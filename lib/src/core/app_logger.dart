import 'dart:convert';

import 'package:flutter/foundation.dart';

enum AppLogLevel { debug, info, warning, error }

/// Minimal structured logger for local diagnostics.
///
/// Countora intentionally does not log timer names, backup contents, or other
/// user-created data. Structured fields are redacted again by key as defense in
/// depth before a line is emitted.
class AppLogger {
  const AppLogger(this.component);

  final String component;

  void debug(String event, {Map<String, Object?> fields = const {}}) {
    if (kDebugMode) _write(AppLogLevel.debug, event, fields);
  }

  void info(String event, {Map<String, Object?> fields = const {}}) {
    _write(AppLogLevel.info, event, fields);
  }

  void warning(
    String event, {
    Object? error,
    Map<String, Object?> fields = const {},
  }) {
    _write(
      AppLogLevel.warning,
      event,
      <String, Object?>{
        ...fields,
        if (error != null) 'errorType': error.runtimeType.toString(),
      },
    );
  }

  void error(
    String event, {
    Object? error,
    Map<String, Object?> fields = const {},
  }) {
    _write(
      AppLogLevel.error,
      event,
      <String, Object?>{
        ...fields,
        if (error != null) 'errorType': error.runtimeType.toString(),
      },
    );
  }

  void _write(
    AppLogLevel level,
    String event,
    Map<String, Object?> fields,
  ) {
    final payload = <String, Object?>{
      'timeUtc': DateTime.now().toUtc().toIso8601String(),
      'level': level.name,
      'component': component,
      'event': event,
      if (fields.isNotEmpty) 'fields': sanitizeLogFields(fields),
    };
    debugPrint(jsonEncode(payload));
  }
}

/// Returns JSON-encodable diagnostic fields with sensitive values removed.
///
/// This helper accepts nested maps regardless of their generic key/value types.
/// That matters at logging boundaries because plugin/platform data can arrive as
/// `Map<Object?, Object?>`; stringifying such a map would bypass key-based
/// redaction of nested credentials.
Map<String, Object?> sanitizeLogFields(Map<String, Object?> source) {
  return source.map((key, value) {
    if (_isSensitiveLogKey(key)) {
      return MapEntry(key, '[REDACTED]');
    }
    return MapEntry(key, _sanitizeLogValue(value));
  });
}

Object? _sanitizeLogValue(Object? value) {
  if (value is Map) {
    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      normalized['${entry.key}'] = entry.value;
    }
    return sanitizeLogFields(normalized);
  }

  if (value is Iterable) {
    return value
        .map(_sanitizeLogValue)
        .toList(growable: false);
  }

  return _safeLogScalar(value);
}

Object? _safeLogScalar(Object? value) {
  if (value == null || value is num || value is bool) return value;
  if (value is Enum) return value.name;
  final text = value.toString();
  return text.length <= 200 ? text : '${text.substring(0, 200)}…';
}

bool _isSensitiveLogKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  return _sensitiveLogKeys.any(normalized.contains);
}

const _sensitiveLogKeys = <String>[
  'password',
  'passcode',
  'pin',
  'token',
  'secret',
  'authorization',
  'credential',
  'apikey',
  'privatekey',
  'cookie',
  'sessionid',
  'email',
  'phone',
  'backup',
  'payload',
  'timername',
  'username',
];
