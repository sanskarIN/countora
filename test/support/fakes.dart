import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/data/notification_service.dart';
import 'package:countora/src/domain/models.dart';

class MemoryTimerStore implements TimerStore {
  MemoryTimerStore({this.state = const CountoraState()});

  CountoraState state;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
    state = const CountoraState();
  }

  @override
  Future<CountoraState> load() async => state;

  @override
  Future<void> save(CountoraState state) async {
    saveCount += 1;
    this.state = state;
  }
}

class FakeNotificationService implements NotificationService {
  final List<String> scheduled = <String>[];
  final List<String> cancelled = <String>[];
  int permissionRequests = 0;

  @override
  Future<void> cancelTimer(String timerId) async {
    cancelled.add(timerId);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {
    permissionRequests += 1;
  }

  @override
  Future<void> scheduleTimer(
    CountdownTimer timer, {
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool quietMode,
  }) async {
    scheduled.add(timer.id);
  }
}
