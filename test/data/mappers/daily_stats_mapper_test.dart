import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/daily_stats_mapper.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('round-trips daily counters', () async {
    final stats = DailyStats.empty(const LocalDate(19723)).copyWith(
      newWordsStudied: 4,
      reviewsCompleted: 6,
      xpGained: 30,
      correctAnswers: 5,
    );

    await db
        .into(db.dailyStatsTable)
        .insert(DailyStatsMapper.toCompanion(stats));
    final row = (await db.select(db.dailyStatsTable).get()).single;

    expect(row.dateEpochDays, 19723);
    expect(DailyStatsMapper.toDomain(row), stats);
  });

  test('supports the epoch day and a negative day', () async {
    for (final days in [0, -1]) {
      final stats = DailyStats.empty(LocalDate(days));
      await db
          .into(db.dailyStatsTable)
          .insert(DailyStatsMapper.toCompanion(stats));
    }

    final rows = await db.select(db.dailyStatsTable).get();
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.dateEpochDays), containsAll(<int>[0, -1]));
  });
}
