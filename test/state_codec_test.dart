import 'dart:convert';

import 'package:countora/src/data/state_codec.dart';
import 'package:countora/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StateCodec', () {
    test('round trips current state schema', () {
      const state = CountoraState(
        settings: CountoraSettings(compactCards: true),
      );

      final decoded = StateCodec.decode(StateCodec.encode(state));

      expect(decoded.settings.compactCards, isTrue);
    });

    test('rejects a newer schema instead of silently downgrading it', () {
      final raw = jsonEncode(<String, Object?>{
        'schemaVersion': StateCodec.currentSchemaVersion + 1,
        'timers': <Object?>[],
        'presets': <Object?>[],
        'history': <Object?>[],
        'settings': const CountoraSettings().toJson(),
      });

      expect(() => StateCodec.decode(raw), throwsFormatException);
    });

    test('rejects fractional schema versions', () {
      final raw = jsonEncode(<String, Object?>{
        'schemaVersion': 1.5,
        'timers': <Object?>[],
        'presets': <Object?>[],
        'history': <Object?>[],
        'settings': const CountoraSettings().toJson(),
      });

      expect(() => StateCodec.decode(raw), throwsFormatException);
    });
  });
}
