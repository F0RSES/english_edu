import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/word_mapper.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// `WordRepository` поверх Drift.
///
/// `WordRepository.getByStatus` здесь нет: статус живёт в `WordProgress`
/// (ADR-004), поэтому выборка по статусу — `ProgressRepository` или JOIN
/// на стороне прогресса.
final class DriftWordRepository implements WordRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftWordRepository(this._db);

  final AppDatabase _db;

  @override
  Future<domain.Word?> getById(WordId id) async {
    final row =
        await (_db.select(_db.words)
              ..where((t) => t.id.equals(id.value))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : WordMapper.toDomain(row);
  }

  @override
  Future<List<domain.Word>> getByIds(Iterable<WordId> ids) async {
    final values = ids.map((id) => id.value).toList();
    if (values.isEmpty) {
      return const [];
    }
    final rows = await (_db.select(
      _db.words,
    )..where((t) => t.id.isIn(values))).get();
    return rows.map(WordMapper.toDomain).toList();
  }

  @override
  Future<List<domain.Word>> getAll() async {
    final rows = await _db.select(_db.words).get();
    return rows.map(WordMapper.toDomain).toList();
  }

  @override
  Future<int> count() async {
    final total = _db.words.id.count();
    final row = await (_db.selectOnly(
      _db.words,
    )..addColumns([total])).getSingle();
    final value = row.read(total);
    return value ?? 0;
  }

  /// Возвращает `MAX(id) + 1` одним запросом, без чтения таблицы в память.
  ///
  /// `COALESCE` нужен для пустой таблицы: `MAX(id)` вернул бы `NULL`.
  @override
  Future<WordId> nextId() async {
    final row = await _db
        .customSelect('SELECT COALESCE(MAX(id), 0) AS max_id FROM words')
        .getSingle();
    return WordId(row.read<int>('max_id') + 1);
  }

  /// Точное совпадение по нормализованному term (ADR-024).
  ///
  /// Сравнение в SQL, а не в Dart: нужен один конкретный термин, а не
  /// подстрока, и таблица слов уже проиндексирована по `term`
  /// (`idx_words_term`). `term` в БД нормализован при записи, поэтому `equals`
  /// достаточно.
  @override
  Future<domain.Word?> findByTerm(String term) async {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.words)
              ..where((t) => t.term.equals(normalized))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : WordMapper.toDomain(row);
  }

  /// Ищет по term ИЛИ translation без учёта регистра.
  ///
  /// Фильтрация в Dart, а не в SQL: `LIKE` в SQLite регистронезависим только
  /// для ASCII, а переводы кириллические. Для словаря в сотни слов линейный
  /// проход дешевле, чем FTS-индекс; при росте объёма — BL-32.
  @override
  Future<List<domain.Word>> search(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return const [];
    }
    final rows = await _db.select(_db.words).get();
    return [
      for (final row in rows)
        if (row.term.toLowerCase().contains(needle) ||
            row.translation.toLowerCase().contains(needle))
          WordMapper.toDomain(row),
    ];
  }

  @override
  Future<void> upsert(domain.Word word) async {
    await _db
        .into(_db.words)
        .insertOnConflictUpdate(WordMapper.toCompanion(word));
  }

  @override
  Future<void> insertMany(Iterable<domain.Word> words) async {
    await _db.transaction(() async {
      for (final word in words) {
        await _db.into(_db.words).insert(WordMapper.toCompanion(word));
      }
    });
  }

  @override
  Future<void> delete(WordId id) async {
    await (_db.delete(_db.words)..where((t) => t.id.equals(id.value))).go();
  }

  @override
  Future<void> replaceAll(Iterable<domain.Word> words) async {
    await _db.transaction(() async {
      await _db.delete(_db.words).go();
      for (final word in words) {
        await _db.into(_db.words).insert(WordMapper.toCompanion(word));
      }
    });
  }
}
