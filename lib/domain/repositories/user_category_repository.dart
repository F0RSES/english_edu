import 'package:english_edu/domain/value_objects/user_category.dart';

/// Хранилище категорий слов (ADR-034).
///
/// Категория — отдельная сущность, а не строка в `Word.category`: нужны цвет,
/// запрет дублей и удаление. Само слово по-прежнему хранит только имя, поэтому
/// старые данные работают без миграции.
abstract interface class UserCategoryRepository {
  /// Все категории, базовые и пользовательские, по возрастанию `id`.
  Future<List<UserCategory>> getAll();

  /// Ищет категорию по имени без учёта регистра и пробелов по краям.
  Future<UserCategory?> findByName(String name);

  /// Создаёт категорию; время создания берётся из часов репозитория.
  ///
  /// Бросает исключение БД при попытке создать дубль: `UNIQUE (name)` — это
  /// последняя линия обороны, а понятное сообщение даёт use case.
  Future<UserCategory> create(String name, {String? colorHex});

  /// Удаляет категорию по [id]; слова с этой категорией не меняются.
  Future<void> delete(int id);
}
