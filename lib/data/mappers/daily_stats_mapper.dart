import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// Domain `DailyStats` ↔ Drift `DailyStatsRow`.
///
/// Первичный ключ — `LocalDate.daysSinceEpoch`.
final class DailyStatsMapper {
  DailyStatsMapper._();

  /// Собирает счётчики дня из строки БД.
  static DailyStats toDomain(DailyStatsRow row) => DailyStats(
    date: LocalDate(row.dateEpochDays),
    newWordsStudied: row.newWordsStudied,
    reviewsCompleted: row.reviewsCompleted,
    xpGained: row.xpGained,
    correctAnswers: row.correctAnswers,
  );

  /// Раскладывает счётчики дня в companion.
  static DailyStatsTableCompanion toCompanion(DailyStats stats) =>
      DailyStatsTableCompanion(
        dateEpochDays: Value(stats.date.daysSinceEpoch),
        newWordsStudied: Value(stats.newWordsStudied),
        reviewsCompleted: Value(stats.reviewsCompleted),
        xpGained: Value(stats.xpGained),
        correctAnswers: Value(stats.correctAnswers),
      );
}
