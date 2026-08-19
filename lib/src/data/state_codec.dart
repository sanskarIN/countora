import 'dart:convert';

import '../domain/models.dart';

/// Decodes Countora's internal persisted state and owns schema migrations.
///
/// Local persistence is deliberately more tolerant than backup import because
/// an optional damaged field should not make the entire app unusable. Schema
/// versions are still validated so newer state is never silently interpreted by
/// older code.
abstract final class StateCodec {
  static const int currentSchemaVersion = 1;

  static String encode(CountoraState state) => jsonEncode(state.toJson());

  static CountoraState decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Persisted Countora state is not an object.');
    }

    var document = decoded.map((key, value) => MapEntry('$key', value));
    final rawVersion = document['schemaVersion'];
    if (rawVersion is! num || rawVersion.toInt() != rawVersion) {
      throw const FormatException('Persisted Countora schema is invalid.');
    }

    var version = rawVersion.toInt();
    if (version <= 0 || version > currentSchemaVersion) {
      throw const FormatException('Persisted Countora schema is unsupported.');
    }

    while (version < currentSchemaVersion) {
      document = _migrate(document, version);
      version += 1;
      document['schemaVersion'] = version;
    }

    return CountoraState.fromJson(document);
  }

  static Map<String, Object?> _migrate(
    Map<String, Object?> document,
    int fromVersion,
  ) {
    switch (fromVersion) {
      // Add explicit migrations here when schema version 2+ is introduced.
      default:
        throw FormatException(
          'No Countora state migration exists from schema $fromVersion.',
        );
    }
  }
}
