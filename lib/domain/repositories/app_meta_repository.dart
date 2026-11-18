/// Служебные метаданные приложения (Phase 39c).
///
/// Внутреннее состояние устройства (например, версия seed-контента):
/// не экспортируется и не синхронизируется, в отличие от настроек.
abstract interface class AppMetaRepository {
  /// Ключ максимального id seed-словаря (Phase 39e): отличает seed-слова
  /// от пользовательских при ручном сбросе прогресса.
  static const seedMaxIdKey = 'seed_max_id';

  /// Значение по ключу [key] или null, если ключа нет.
  Future<String?> getValue(String key);

  /// Записывает [value] по ключу [key], перезаписывая прежнее значение.
  Future<void> setValue(String key, String value);
}
