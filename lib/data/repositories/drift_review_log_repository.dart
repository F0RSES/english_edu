import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/review_log_mapper.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// `ReviewLogRepository` поверх Drift.
final class DriftReviewLogRepository implements ReviewLogRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftReviewLogRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> append(ReviewLog log) async {
    await _db.into(_db.reviewLogs).insert(ReviewLogMapper.toCompanion(log));
  }

  @override
  Future<List<ReviewLog>> getByWordId(WordId wordId) async {
    final rows =
        await (_db.select(_db.reviewLogs)
              ..where((t) => t.wordId.equals(wordId.value))
              ..orderBy([(t) => OrderingTerm.asc(t.reviewedAtUtc)]))
            .get();
    return rows.map(ReviewLogMapper.toDomain).toList();
  }

  @override
  Future<List<ReviewLog>> getAll() async {
    final rows = await (_db.select(
      _db.reviewLogs,
    )..orderBy([(t) => OrderingTerm.asc(t.reviewedAtUtc)])).get();
    return rows.map(ReviewLogMapper.toDomain).toList();
  }

  @override
  Future<List<ReviewLog>> getByDateRange(
    DateTime fromUtc,
    DateTime toUtc,
  ) async {
    if (!fromUtc.isUtc || !toUtc.isUtc) {
      throw ArgumentError('fromUtc and toUtc must be UTC');
    }
    final from = fromUtc.millisecondsSinceEpoch;
    final to = toUtc.millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.reviewLogs)
              ..where(
                (t) =>
                    t.reviewedAtUtc.isBiggerOrEqualValue(from) &
                    t.reviewedAtUtc.isSmallerThanValue(to),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.reviewedAtUtc)]))
            .get();
    return rows.map(ReviewLogMapper.toDomain).toList();
  }

  /// Исключение из append-only: только импорт и восстановление.
  @override
  Future<void> replaceAll(Iterable<ReviewLog> logs) async {
    await _db.transaction(() async {
      await _db.delete(_db.reviewLogs).go();
      for (final log in logs) {
        await _db.into(_db.reviewLogs).insert(ReviewLogMapper.toCompanion(log));
      }
    });
  }

  /// Исключение из append-only: только `UndoLastReview` (ADR-010).
  @override
  Future<void> delete(ReviewLogId id) async {
    await (_db.delete(
      _db.reviewLogs,
    )..where((t) => t.id.equals(id.value))).go();
  }
}
