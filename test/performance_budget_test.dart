import 'package:countora/src/domain/backup_codec.dart';
import 'package:countora/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('large supported backup round trips inside the local performance budget', () {
    final completedAt = DateTime.utc(2026, 8, 19, 8);
    final state = CountoraState(
      history: List<TimerHistoryEntry>.generate(
        BackupCodec.maxHistoryEntries,
        (index) => TimerHistoryEntry(
          timerId: 'timer-$index',
          name: 'History $index',
          group: 'Benchmark',
          completedAtUtc: completedAt,
          totalDurationSeconds: 300,
        ),
      ),
    );

    final stopwatch = Stopwatch()..start();
    var encoded = '';
    for (var iteration = 0; iteration < 10; iteration += 1) {
      encoded = BackupCodec.encode(state);
      final decoded = BackupCodec.decode(encoded);
      expect(decoded.history, hasLength(BackupCodec.maxHistoryEntries));
    }
    stopwatch.stop();

    expect(encoded.length, lessThan(BackupCodec.maxBackupBytes));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
