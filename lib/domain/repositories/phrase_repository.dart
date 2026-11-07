import 'package:english_edu/domain/entities/phrase.dart';

/// Справочник фраз (ADR-038).
///
/// Только чтение: контент приходит из ассетов, пользователь его не правит —
/// поэтому ни `save`, ни `delete` в контракте нет.
abstract interface class PhraseRepository {
  /// Все фразы в порядке `id`.
  Future<List<Phrase>> getAll();

  /// Фразы выбранной темы.
  Future<List<Phrase>> getByCategory(String category);

  /// Сколько фраз загружено.
  Future<int> count();

  /// Атомарно вставляет фразы (загрузка seed).
  Future<void> insertMany(Iterable<Phrase> phrases);
}
