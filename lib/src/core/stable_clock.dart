/// A session clock that advances from a monotonic source rather than repeatedly
/// trusting the device wall clock.
///
/// Countdown durations are relative. Anchoring wall-clock UTC once and then
/// advancing it using a monotonic elapsed-time source prevents a user or OS
/// wall-clock adjustment from unexpectedly adding or removing time while the
/// Countora process remains alive. After a process restart, persisted UTC timer
/// deadlines provide the recovery anchor.
class StableClock {
  StableClock({
    DateTime Function()? wallNowUtc,
    Duration Function()? monotonicElapsed,
  })  : _wallNowUtc = wallNowUtc ?? (() => DateTime.now().toUtc()),
        _monotonicElapsed = monotonicElapsed ?? _stopwatchElapsed() {
    _anchorUtc = _wallNowUtc();
    _anchorMonotonic = _monotonicElapsed();
  }

  final DateTime Function() _wallNowUtc;
  final Duration Function() _monotonicElapsed;
  late final DateTime _anchorUtc;
  late final Duration _anchorMonotonic;

  DateTime nowUtc() {
    return _anchorUtc.add(_monotonicElapsed() - _anchorMonotonic);
  }

  /// Difference between the mutable device wall clock and Countora's stable
  /// session clock. This is useful for diagnostics without altering timers.
  Duration get wallClockDrift => _wallNowUtc().difference(nowUtc());

  static Duration Function() _stopwatchElapsed() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }
}
