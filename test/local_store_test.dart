import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists and reloads Countora state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesTimerStore(preferences);

    const state = CountoraState(
      settings: CountoraSettings(quietMode: true),
    );
    await store.save(state);

    final reloaded = await store.load();
    expect(reloaded.settings.quietMode, isTrue);
  });

  test('recovers a valid staged write when the primary is corrupt', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'countora_state_v1': '{not json',
      'countora_state_pending_v1':
          '{"schemaVersion":1,"timers":[],"presets":[],"history":[],"settings":{"themeMode":"system","notificationsEnabled":true,"soundEnabled":true,"vibrationEnabled":true,"quietMode":true,"reducedMotion":false,"compactCards":false,"onboardingSeen":false}}',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesTimerStore(preferences);

    final recovered = await store.load();

    expect(recovered.settings.quietMode, isTrue);
    expect(preferences.getString('countora_state_v1'), contains('quietMode'));
  });

  test('falls back to the last known good backup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'countora_state_v1': 'broken',
      'countora_state_backup_v1':
          '{"schemaVersion":1,"timers":[],"presets":[],"history":[],"settings":{"themeMode":"dark","notificationsEnabled":true,"soundEnabled":true,"vibrationEnabled":true,"quietMode":false,"reducedMotion":false,"compactCards":false,"onboardingSeen":false}}',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesTimerStore(preferences);

    final recovered = await store.load();

    expect(recovered.settings.themeMode.name, 'dark');
  });
}
