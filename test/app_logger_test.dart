import 'package:countora/src/core/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

enum _ExampleState { ready }

void main() {
  group('sanitizeLogFields', () {
    test('redacts sensitive values at every nested map depth', () {
      final nested = <Object?, Object?>{
        'safe': 'kept',
        'credentials': <Object?, Object?>{
          'api_key': 'should-not-leak',
          'details': <Object?, Object?>{
            'supportEmail': 'person@example.test',
          },
        },
      };

      final result = sanitizeLogFields(<String, Object?>{'platform': nested});
      final platform = result['platform']! as Map<String, Object?>;
      final credentials = platform['credentials']! as Map<String, Object?>;
      final details = credentials['details']! as Map<String, Object?>;

      expect(platform['safe'], 'kept');
      expect(credentials['api_key'], '[REDACTED]');
      expect(details['supportEmail'], '[REDACTED]');
    });

    test('recursively sanitizes maps inside iterables', () {
      final result = sanitizeLogFields(<String, Object?>{
        'items': <Object?>[
          <Object?, Object?>{'token': 'hidden', 'stepIndex': 2},
          _ExampleState.ready,
        ],
      });
      final items = result['items']! as List<Object?>;
      final first = items.first! as Map<String, Object?>;

      expect(first['token'], '[REDACTED]');
      expect(first['stepIndex'], 2);
      expect(items[1], 'ready');
    });

    test('bounds arbitrary scalar text while preserving safe primitives', () {
      final longValue = List<String>.filled(250, 'x', growable: false).join();
      final result = sanitizeLogFields(<String, Object?>{
        'count': 3,
        'enabled': true,
        'longValue': longValue,
      });

      expect(result['count'], 3);
      expect(result['enabled'], isTrue);
      expect((result['longValue']! as String).length, 201);
      expect(result['longValue'], endsWith('…'));
    });

    test('normalizes punctuation and case when matching sensitive keys', () {
      final result = sanitizeLogFields(<String, Object?>{
        'Authorization-Header': 'Bearer secret',
        'PRIVATE_KEY': 'hidden',
        'session-id': 'hidden',
      });

      expect(result.values, everyElement('[REDACTED]'));
    });
  });
}
