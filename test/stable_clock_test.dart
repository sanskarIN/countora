import 'package:countora/src/core/stable_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'advances from its initial wall-clock anchor using monotonic elapsed time',
    () {
      var wallNow = DateTime.utc(2026, 8, 19, 9);
      var elapsed = Duration.zero;
      final clock = StableClock(
        wallNowUtc: () => wallNow,
        elapsed: () => elapsed,
      );

      elapsed = const Duration(minutes: 2, seconds: 3);
      wallNow = DateTime.utc(2030, 1, 1);

      expect(clock.nowUtc(), DateTime.utc(2026, 8, 19, 9, 2, 3));
    },
  );

  test('normalizes a non-UTC anchor', () {
    var elapsed = const Duration(seconds: 30);
    final clock = StableClock(
      wallNowUtc: () => DateTime.parse('2026-08-19T14:30:00+05:30'),
      elapsed: () => elapsed,
    );

    expect(clock.nowUtc(), DateTime.utc(2026, 8, 19, 9, 0, 30));
  });
}
