import 'package:countora/src/data/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldPreserveDueRuntimeNotification', () {
    final deadline = DateTime.utc(2026, 8, 20, 1, 2, 3);

    test('does not preserve a callback before its deadline', () {
      expect(
        shouldPreserveDueRuntimeNotification(
          scheduledAtUtc: deadline,
          nowUtc: deadline.subtract(const Duration(microseconds: 1)),
        ),
        isFalse,
      );
    });

    test('preserves a callback at the exact deadline', () {
      expect(
        shouldPreserveDueRuntimeNotification(
          scheduledAtUtc: deadline,
          nowUtc: deadline,
        ),
        isTrue,
      );
    });

    test('preserves a callback after its deadline', () {
      expect(
        shouldPreserveDueRuntimeNotification(
          scheduledAtUtc: deadline,
          nowUtc: deadline.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('normalizes non-UTC timestamps before comparison', () {
      final localDeadline = DateTime.parse('2026-08-20T06:32:03+05:30');
      expect(
        shouldPreserveDueRuntimeNotification(
          scheduledAtUtc: localDeadline,
          nowUtc: deadline,
        ),
        isTrue,
      );
    });
  });
}
