/// Служебные метаданные приложения (Phase 39c).
///
/// Внутреннее состояние устройства (например, версия seed-контента):
/// не экспортируется и не синхронизируется, в отличие от настроек.
abstract interface class AppMetaRepository {
  /// Значение по ключу [key] или null, если ключа нет.
  Future<String?> getValue(String key);

  /// Записывает [value] по ключу [key], перезаписывая прежнее значение.
  Future<void> setValue(String key, String value);
}
