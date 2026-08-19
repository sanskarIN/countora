/// Runtime clock used by countdown calculations.
///
/// A wall-clock timestamp is captured once, then advanced with Dart's monotonic
/// [Stopwatch]. This prevents active countdowns from jumping when the user or
/// operating system adjusts the wall clock while Countora remains alive.
/// Persisted deadlines still use UTC instants so timers can be restored after a
/// process restart.
class StableClock {
  StableClock({
    DateTime Function()? wallNowUtc,
    Duration Function()? elapsed,
  })  : _anchorUtc = (wallNowUtc ?? _systemNowUtc)().toUtc(),
        _elapsed = elapsed ?? _startMonotonicReader();

  final DateTime _anchorUtc;
  final Duration Function() _elapsed;

  DateTime nowUtc() => _anchorUtc.add(_elapsed());

  static DateTime _systemNowUtc() => DateTime.now().toUtc();

  static Duration Function() _startMonotonicReader() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }
}
