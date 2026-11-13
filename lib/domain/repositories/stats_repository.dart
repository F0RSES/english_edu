import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// Read and write access to per-day aggregates.
abstract interface class StatsRepository {
  /// Returns the counters of [date], or null when the day has no record.
  Future<DailyStats?> getForDate(LocalDate date);

  /// Returns counters for the inclusive range `[from, to]`, oldest first.
  Future<List<DailyStats>> getRange(LocalDate from, LocalDate to);

  /// Returns the local date of the most recent day with any answers.
  ///
  /// Null when the history is empty. A descending index on the date column
  /// is the implementation's concern in Phase 2, not part of this contract.
  Future<LocalDate?> getLastActiveDate();

  /// Inserts [stats] or replaces the record for the same date.
  Future<void> upsert(DailyStats stats);

  /// Returns every stored day.
  ///
  /// Used by export; ordering is implementation-defined.
  Future<List<DailyStats>> getAll();

  /// Атомарно заменяет всю статистику.
  ///
  /// Для импорта и восстановления.
  Future<void> replaceAll(Iterable<DailyStats> items);
}
