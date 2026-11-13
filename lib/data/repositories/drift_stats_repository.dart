import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/daily_stats_mapper.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// `StatsRepository` поверх Drift.
final class DriftStatsRepository implements StatsRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftStatsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<DailyStats?> getForDate(LocalDate date) async {
    final row =
        await (_db.select(_db.dailyStatsTable)
              ..where((t) => t.dateEpochDays.equals(date.daysSinceEpoch))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : DailyStatsMapper.toDomain(row);
  }

  @override
  Future<List<DailyStats>> getRange(LocalDate from, LocalDate to) async {
    final rows =
        await (_db.select(_db.dailyStatsTable)
              ..where(
                (t) =>
                    t.dateEpochDays.isBiggerOrEqualValue(from.daysSinceEpoch) &
                    t.dateEpochDays.isSmallerOrEqualValue(to.daysSinceEpoch),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.dateEpochDays)]))
            .get();
    return rows.map(DailyStatsMapper.toDomain).toList();
  }

  @override
  Future<List<DailyStats>> getAll() async {
    final rows = await (_db.select(
      _db.dailyStatsTable,
    )..orderBy([(t) => OrderingTerm.asc(t.dateEpochDays)])).get();
    return rows.map(DailyStatsMapper.toDomain).toList();
  }

  @override
  Future<LocalDate?> getLastActiveDate() async {
    final totalAnswers =
        _db.dailyStatsTable.newWordsStudied +
        _db.dailyStatsTable.reviewsCompleted;
    final maxDays = _db.dailyStatsTable.dateEpochDays.max();
    final query = _db.selectOnly(_db.dailyStatsTable)
      ..addColumns([maxDays])
      ..where(totalAnswers.isBiggerThanValue(0));
    final row = await query.getSingle();
    final value = row.read(maxDays);
    return value == null ? null : LocalDate(value);
  }

  @override
  Future<void> upsert(DailyStats stats) async {
    await _db
        .into(_db.dailyStatsTable)
        .insertOnConflictUpdate(DailyStatsMapper.toCompanion(stats));
  }

  @override
  Future<void> replaceAll(Iterable<DailyStats> items) async {
    await _db.transaction(() async {
      await _db.delete(_db.dailyStatsTable).go();
      for (final item in items) {
        await _db
            .into(_db.dailyStatsTable)
            .insert(DailyStatsMapper.toCompanion(item));
      }
    });
  }
}
