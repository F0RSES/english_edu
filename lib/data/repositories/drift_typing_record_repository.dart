import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/typing_record_repository.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';

/// `TypingRecordRepository` поверх Drift (ADR-037).
final class DriftTypingRecordRepository implements TypingRecordRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftTypingRecordRepository(this._db);

  final AppDatabase _db;

  @override
  Future<TypingRecord?> getBest() async {
    final row =
        await (_db.select(_db.typingRecords)
              ..orderBy([(t) => OrderingTerm.desc(t.score)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<TypingRecord>> getTop({int limit = 10}) async {
    final rows =
        await (_db.select(_db.typingRecords)
              ..orderBy([(t) => OrderingTerm.desc(t.score)])
              ..limit(limit))
            .get();
    return [for (final row in rows) _toDomain(row)];
  }

  @override
  Future<TypingRecord> save(TypingRecord record) async {
    if (!record.createdAtUtc.isUtc) {
      throw ArgumentError.value(
        record.createdAtUtc,
        'createdAtUtc',
        'must be UTC',
      );
    }
    final id = await _db
        .into(_db.typingRecords)
        .insert(
          TypingRecordsCompanion.insert(
            wordsCount: record.wordsCount,
            correctCount: record.correctCount,
            durationSeconds: record.durationSeconds,
            wpm: record.wpm,
            accuracyPercent: record.accuracyPercent,
            score: record.score,
            createdAtUtc: record.createdAtUtc.millisecondsSinceEpoch,
          ),
        );
    return TypingRecord(
      id: id,
      wordsCount: record.wordsCount,
      correctCount: record.correctCount,
      durationSeconds: record.durationSeconds,
      wpm: record.wpm,
      accuracyPercent: record.accuracyPercent,
      score: record.score,
      createdAtUtc: record.createdAtUtc,
    );
  }

  TypingRecord _toDomain(TypingRecordRow row) => TypingRecord(
    id: row.id,
    wordsCount: row.wordsCount,
    correctCount: row.correctCount,
    durationSeconds: row.durationSeconds,
    wpm: row.wpm,
    accuracyPercent: row.accuracyPercent,
    score: row.score,
    createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtc,
      isUtc: true,
    ),
  );
}
