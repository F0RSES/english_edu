import 'package:english_edu/core/notifications/notification_service.dart';

/// Шпион: запоминает вызовы вместо работы с плагином.
final class FakeNotificationService implements NotificationService {
  /// Сколько раз спрашивали разрешение.
  int requestPermissionCalls = 0;

  /// Вызовы планирования в порядке поступления.
  final List<({int hour, int minute})> scheduleCalls = [];

  /// Сколько раз снимали уведомления.
  int cancelCalls = 0;

  /// Заставляет [scheduleDailyReminder] бросить исключение.
  bool throwOnSchedule = false;

  @override
  Future<void> requestPermission() async {
    requestPermissionCalls++;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (throwOnSchedule) {
      throw StateError('schedule failed');
    }
    scheduleCalls.add((hour: hour, minute: minute));
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
  }
}
