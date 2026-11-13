import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/word_progress_mapper.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// `ProgressRepository` поверх Drift.
final class DriftProgressRepository implements ProgressRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftProgressRepository(this._db);

  final AppDatabase _db;

  @override
  Future<WordProgress?> getByWordId(WordId wordId) async {
    final row =
        await (_db.select(_db.wordProgresses)
              ..where((t) => t.wordId.equals(wordId.value))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : WordProgressMapper.toDomain(row);
  }

  @override
  Future<List<WordProgress>> getByStatus(WordStatus status) async {
    final rows = await (_db.select(
      _db.wordProgresses,
    )..where((t) => t.status.equals(status.name))).get();
    return rows.map(WordProgressMapper.toDomain).toList();
  }

  @override
  Future<List<WordProgress>> getAll() async {
    final rows = await _db.select(_db.wordProgresses).get();
    return rows.map(WordProgressMapper.toDomain).toList();
  }

  @override
  Future<List<WordProgress>> getDueBefore(DateTime utcInstant) async {
    if (!utcInstant.isUtc) {
      throw ArgumentError.value(utcInstant, 'utcInstant', 'must be UTC');
    }
    final bound = utcInstant.millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.wordProgresses)
              ..where((t) => t.dueAtUtc.isSmallerOrEqualValue(bound))
              ..orderBy([(t) => OrderingTerm.asc(t.dueAtUtc)]))
            .get();
    return rows.map(WordProgressMapper.toDomain).toList();
  }

  @override
  Future<void> upsert(WordProgress progress) async {
    await _db
        .into(_db.wordProgresses)
        .insertOnConflictUpdate(WordProgressMapper.toCompanion(progress));
  }

  @override
  Future<void> replaceAll(Iterable<WordProgress> items) async {
    await _db.transaction(() async {
      await _db.delete(_db.wordProgresses).go();
      for (final item in items) {
        await _db
            .into(_db.wordProgresses)
            .insert(WordProgressMapper.toCompanion(item));
      }
    });
  }
}
