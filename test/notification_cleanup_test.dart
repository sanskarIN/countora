import 'package:countora/src/data/notification_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attempts later notification cleanup after an earlier failure', () async {
    final attempted = <int>[];
    final failures = <int>[];

    await runBoundedNotificationCleanup(
      count: 4,
      cancel: (index) async {
        attempted.add(index);
        if (index == 1) throw StateError('simulated cancellation failure');
      },
      onError: (index, _) => failures.add(index),
    );

    expect(attempted, <int>[0, 1, 2, 3]);
    expect(failures, <int>[1]);
  });

  test('does nothing for an empty cleanup range', () async {
    var attempted = false;

    await runBoundedNotificationCleanup(
      count: 0,
      cancel: (_) async => attempted = true,
      onError: (_, __) {},
    );

    expect(attempted, isFalse);
  });
}
