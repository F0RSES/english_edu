import 'package:meta/meta.dart';

/// Итог одного прохода синхронизации.
///
/// Счётчики нужны UI: «отправлено 12, получено 3» понятнее, чем молчаливое
/// завершение.
@immutable
final class SyncReport {
  /// Создаёт отчёт; оба счётчика неотрицательны.
  const SyncReport({required this.pushed, required this.pulled})
    : assert(pushed >= 0, 'pushed must be >= 0'),
      assert(pulled >= 0, 'pulled must be >= 0');

  /// Ничего не изменилось.
  static const empty = SyncReport(pushed: 0, pulled: 0);

  /// Сколько строк ушло в облако.
  final int pushed;

  /// Сколько строк применено локально.
  final int pulled;

  /// Складывает два отчёта — для сценария «push, затем pull».
  SyncReport operator +(SyncReport other) =>
      SyncReport(pushed: pushed + other.pushed, pulled: pulled + other.pulled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncReport && pushed == other.pushed && pulled == other.pulled;

  @override
  int get hashCode => Object.hash(pushed, pulled);

  @override
  String toString() => 'SyncReport(pushed: $pushed, pulled: $pulled)';
}

/// Ошибка синхронизации: нет сети, нет авторизации, ответ не той схемы.
///
/// Отдельный тип нужен, чтобы экран отличал «не настроено/не вошёл» от прочих
/// сбоев и не показывал пользователю текст исключения библиотеки.
final class CloudSyncException implements Exception {
  /// Создаёт ошибку с [message].
  const CloudSyncException(this.message);

  /// Причина для лога и UI.
  final String message;

  @override
  String toString() => 'CloudSyncException($message)';
}

/// Синхронизация прогресса с облаком (ADR-022).
///
/// Локальная БД остаётся источником истины: сервис только отправляет снимок и
/// дотягивает более свежие строки. Конфликты разрешаются по времени изменения
/// строки прогресса.
abstract interface class CloudSyncService {
  /// Отправляет все локальные записи прогресса в облако.
  Future<SyncReport> push();

  /// Забирает облачные записи и применяет те, что новее локальных.
  Future<SyncReport> pull();

  /// Синхронизирует в обе стороны: сначала push, затем pull.
  Future<SyncReport> sync();
}

/// Заглушка для ненастроенного облака.
///
/// Позволяет экрану не проверять конфигурацию на каждой операции: любая
/// попытка синхронизации заканчивается [CloudSyncException], которую UI уже
/// умеет показывать.
final class UnavailableCloudSyncService implements CloudSyncService {
  /// Создаёт заглушку.
  const UnavailableCloudSyncService();

  @override
  Future<SyncReport> push() async => throw _notConfigured;

  @override
  Future<SyncReport> pull() async => throw _notConfigured;

  @override
  Future<SyncReport> sync() async => throw _notConfigured;

  static const _notConfigured = CloudSyncException('cloud is not configured');
}
