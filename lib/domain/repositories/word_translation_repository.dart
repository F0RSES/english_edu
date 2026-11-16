import 'package:english_edu/domain/value_objects/word_translation.dart';

/// Хранилище словарных переводов (BL-96): одна запись на термин.
///
/// Кэш расходный и не привязан к словарю: переводятся в том числе слова вне
/// словаря (варианты игр), поэтому запись переживает удаление слова.
abstract interface class WordTranslationRepository {
  /// Возвращает перевод для [term] или null, если его нет.
  Future<WordTranslation?> findByTerm(String term);

  /// Сохраняет перевод, заменяя существующую запись для того же термина.
  ///
  /// [createdAtUtc] должен быть UTC — время в БД хранится только в UTC.
  Future<void> upsert(
    String term,
    WordTranslation translation, {
    required DateTime createdAtUtc,
  });
}
