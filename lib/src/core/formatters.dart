String formatDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  final seconds = safe.inSeconds.remainder(60);

  String two(int value) => value.toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}

String humanizeDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  if (safe.inHours > 0) {
    final minutes = safe.inMinutes.remainder(60);
    return minutes == 0 ? '${safe.inHours}h' : '${safe.inHours}h ${minutes}m';
  }
  if (safe.inMinutes > 0) {
    final seconds = safe.inSeconds.remainder(60);
    return seconds == 0
        ? '${safe.inMinutes}m'
        : '${safe.inMinutes}m ${seconds}s';
  }
  return '${safe.inSeconds}s';
}
