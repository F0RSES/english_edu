import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/word_hint_repository.dart';
import 'package:english_edu/domain/value_objects/word_hint.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// `WordHintRepository` поверх Drift (ADR-019).
///
/// Время создания приходит из домена (`WordHint.createdAtUtc`), репозиторий его
/// только проверяет: системное время в data-слое не читается.
final class DriftWordHintRepository implements WordHintRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftWordHintRepository(this._db);

  final AppDatabase _db;

  @override
  Future<WordHint?> getByWordId(WordId wordId) async {
    final row =
        await (_db.select(_db.wordHints)
              ..where((t) => t.wordId.equals(wordId.value))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return WordHint(
      wordId: WordId(row.wordId),
      term: row.term,
      hintText: row.hintText,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtUtc,
        isUtc: true,
      ),
    );
  }

  @override
  Future<void> upsert(WordHint hint) async {
    // Проверка дублирует assert VO: в release assert вырезан, а не-UTC время в
    // БД испортило бы порядок и сравнения.
    if (!hint.createdAtUtc.isUtc) {
      throw ArgumentError.value(
        hint.createdAtUtc,
        'createdAtUtc',
        'must be UTC',
      );
    }
    await _db
        .into(_db.wordHints)
        .insertOnConflictUpdate(
          WordHintsCompanion.insert(
            wordId: Value(hint.wordId.value),
            term: hint.term,
            hintText: hint.hintText,
            createdAtUtc: hint.createdAtUtc.millisecondsSinceEpoch,
          ),
        );
  }
}
