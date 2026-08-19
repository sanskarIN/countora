import 'package:countora/src/core/stable_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('advances from monotonic elapsed time', () {
    var wall = DateTime.utc(2026, 8, 19, 8);
    var monotonic = Duration.zero;
    final clock = StableClock(
      wallNowUtc: () => wall,
      monotonicElapsed: () => monotonic,
    );

    monotonic = const Duration(minutes: 3);

    expect(clock.nowUtc(), DateTime.utc(2026, 8, 19, 8, 3));
  });

  test('ignores wall-clock jumps while the session remains alive', () {
    var wall = DateTime.utc(2026, 8, 19, 8);
    var monotonic = Duration.zero;
    final clock = StableClock(
      wallNowUtc: () => wall,
      monotonicElapsed: () => monotonic,
    );

    monotonic = const Duration(minutes: 2);
    wall = DateTime.utc(2026, 8, 19, 13);

    expect(clock.nowUtc(), DateTime.utc(2026, 8, 19, 8, 2));
    expect(clock.wallClockDrift, const Duration(hours: 4, minutes: 58));
  });
}
