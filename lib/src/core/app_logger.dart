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
      if (fields.isNotEmpty) 'fields': _redactMap(fields),
    };
    debugPrint(jsonEncode(payload));
  }

  Map<String, Object?> _redactMap(Map<String, Object?> source) {
    return source.map((key, value) {
      final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (_sensitiveKeys.any(normalized.contains)) {
        return MapEntry(key, '[REDACTED]');
      }
      if (value is Map<String, Object?>) {
        return MapEntry(key, _redactMap(value));
      }
      if (value is Iterable<Object?>) {
        return MapEntry(
          key,
          value.map((item) {
            if (item is Map<String, Object?>) return _redactMap(item);
            return _safeScalar(item);
          }).toList(growable: false),
        );
      }
      return MapEntry(key, _safeScalar(value));
    });
  }

  Object? _safeScalar(Object? value) {
    if (value == null || value is num || value is bool) return value;
    if (value is Enum) return value.name;
    final text = value.toString();
    return text.length <= 200 ? text : '${text.substring(0, 200)}…';
  }

  static const _sensitiveKeys = <String>[
    'password',
    'passcode',
    'token',
    'secret',
    'authorization',
    'cookie',
    'email',
    'phone',
    'backup',
    'payload',
    'timername',
    'username',
  ];
}
