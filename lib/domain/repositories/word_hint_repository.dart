import 'package:english_edu/domain/value_objects/word_hint.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Хранилище AI-подсказок (ADR-019).
///
/// Одна подсказка на слово: `wordId` — ключ, поэтому повторная генерация
/// заменяет прежнюю запись вместе с новым `term`.
abstract interface class WordHintRepository {
  /// Возвращает подсказку для [wordId] или null, если её нет.
  Future<WordHint?> getByWordId(WordId wordId);

  /// Сохраняет [hint], заменяя существующую запись для того же слова.
  Future<void> upsert(WordHint hint);
}
