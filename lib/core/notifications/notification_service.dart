import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Идентификатор ежедневного напоминания: одно на приложение.
const _dailyReminderId = 1000;

/// Канал Android: пользователь видит его в системных настройках.
const _channelId = 'daily_reminder';

/// Заголовок канала в системных настройках.
const _channelName = 'Daily reminder';

/// Заголовок уведомления.
const _notificationTitle = 'English Edu';

/// Текст уведомления.
const _notificationBody = 'Пора повторить слова 📚';

/// Локальные напоминания (ADR-017).
///
/// Абстракция отделяет экраны от плагина: `main` создаёт реализацию один раз и
/// кладёт её в DI, тесты подменяют шпионом.
abstract interface class NotificationService {
  /// Спрашивает разрешение у ОС (iOS и Android 13+).
  Future<void> requestPermission();

  /// Планирует ежедневное напоминание на [hour]:[minute] в локальной TZ.
  Future<void> scheduleDailyReminder({required int hour, required int minute});

  /// Снимает все запланированные уведомления.
  Future<void> cancelAll();
}

/// Реализация поверх `flutter_local_notifications`.
///
/// Использует [AndroidScheduleMode.inexactAllowWhileIdle]: точное время
/// потребовало бы `SCHEDULE_EXACT_ALARM`, которое Android 14+ не выдаёт
/// автоматически, а Play ограничивает его использование. Отклонение —
/// ±5–15 минут; если понадобится точность, переключение на `exact` и запрос
/// разрешения — BL-53.
final class FlutterNotificationService implements NotificationService {
  /// Создаёт сервис поверх инициализированного плагина.
  FlutterNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> requestPermission() async {
    // Android 13+.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Повторное планирование не должно оставлять старое время.
    await cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: _notificationTitle,
      body: _notificationBody,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        // importance/priority — дефолтные, поэтому не задаются явно.
        android: AndroidNotificationDetails(_channelId, _channelName),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Повтор каждый день в это же время.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

/// Заглушка: ничего не планирует.
///
/// Используется, когда инициализация плагина или таймзон упала: приложение
/// работает без напоминаний, остальной код вызова не ветвится.
final class NoOpNotificationService implements NotificationService {
  /// Создаёт заглушку.
  const NoOpNotificationService();

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}
