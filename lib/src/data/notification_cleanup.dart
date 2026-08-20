/// Attempts every bounded notification cleanup operation even when one fails.
///
/// Notification plugins can fail per identifier. Stopping after the first
/// failure can leave later interval notifications active, so cleanup is
/// deliberately best-effort across the full bounded range.
Future<void> runBoundedNotificationCleanup({
  required int count,
  required Future<void> Function(int index) cancel,
  required void Function(int index, Object error) onError,
}) async {
  for (var index = 0; index < count; index += 1) {
    try {
      await cancel(index);
    } on Object catch (error) {
      onError(index, error);
    }
  }
}
