import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Read and write access to the vocabulary.
abstract interface class WordRepository {
  /// Returns the word with [id], or null when it is absent.
  Future<Word?> getById(WordId id);

  /// Returns words for [ids] in one batch.
  ///
  /// Implementations are free to return the words in any order and to use a
  /// single `IN` query. An empty [ids] yields an empty result; ids with no
  /// matching word are simply absent from the result.
  Future<List<Word>> getByIds(Iterable<WordId> ids);

  /// Returns every stored word.
  Future<List<Word>> getAll();

  /// Returns words exactly at [level] (Phase 27a).
  ///
  /// Строгое равенство, а не «не выше»: очередь дня и игры берут слова
  /// только выбранного уровня. Пустой список — на этом уровне слов нет.
  Future<List<Word>> getByLevel(CefrLevel level);

  /// Number of stored words.
  ///
  /// Быстрая проверка пустоты: используется seed loader вместо
  /// `getAll().isEmpty`, чтобы не грузить всю таблицу.
  Future<int> count();

  /// Следующий свободный id.
  ///
  /// Реализация — `SELECT COALESCE(MAX(id), 0) + 1`: удалённые id не
  /// переиспользуются, поэтому id остаётся монотонным и не указывает на
  /// чужую строку. Атомарность при параллельных вставках не гарантируется —
  /// транзакция с retry в Phase 5 (BL-39).
  Future<WordId> nextId();

  /// Ищет слово по точному совпадению с [term] (ADR-024).
  ///
  /// Сравнение идёт по нормализованному значению: `term.trim().toLowerCase()`.
  /// Пустая строка после нормализации даёт null. Возвращается первое
  /// совпадение: дубликатов быть не должно, а если они есть — виноват импорт
  /// или ручная правка БД, и выбор конкретной строки ничего не решает.
  ///
  /// Нужен, чтобы не создать вторую карточку для `apple` при вводе `Apple`.
  Future<Word?> findByTerm(String term);

  /// Возвращает все слова с этим [term] (trim + нижний регистр).
  ///
  /// Нужен для гомонимов (ADR-031): `apple` — фрукт и `apple` — компания живут
  /// разными карточками с разными id. Не путать с [findByTerm]: тот отдаёт одно
  /// слово и используется проверками seed/import.
  ///
  /// Пустой список означает, что слова с таким term нет.
  Future<List<Word>> findAllByTerm(String term);

  /// Returns words matching [query] by term or translation.
  ///
  /// Matching is a case-insensitive substring search over term OR
  /// translation; [query] is trimmed before comparison. An empty result
  /// means no matches, not an error.
  Future<List<Word>> search(String query);

  /// Inserts [word] or replaces the existing one with the same id.
  ///
  /// Для одиночного добавления; для batch (seed) — [insertMany].
  Future<void> upsert(Word word);

  /// Атомарно вставляет несколько слов.
  ///
  /// Используется seed loader. Идемпотентность — ответственность вызывающего:
  /// проверить `getAll().isEmpty` перед вызовом. При конфликте id бросается
  /// исключение, а не происходит silent skip.
  Future<void> insertMany(Iterable<Word> words);

  /// Removes the word with [id]; does nothing when it is absent.
  Future<void> delete(WordId id);

  /// Атомарно заменяет все слова.
  ///
  /// Для импорта и восстановления. Одно слово добавляется через [upsert].
  Future<void> replaceAll(Iterable<Word> words);
}
