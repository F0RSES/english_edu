import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_stats_repository.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

DailyStats stats(
  int days, {
  int newWords = 1,
  int reviews = 1,
}) =>
    DailyStats(
      date: LocalDate(days),
      newWordsStudied: newWords,
      reviewsCompleted: reviews,
      xpGained: 10,
      correctAnswers: 1,
    );

void main() {
  late AppDatabase db;
  late DriftStatsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftStatsRepository(db);
  });
  tearDown(() => db.close());

  test('upserts and reads a single day', () async {
    await repo.upsert(stats(19723));

    expect(await repo.getForDate(const LocalDate(19723)), stats(19723));
  });

  test('returns null for a day without a record', () async {
    expect(await repo.getForDate(const LocalDate(19723)), isNull);
  });

  test('reads an inclusive range', () async {
    await repo.replaceAll([stats(19721), stats(19722), stats(19723)]);

    final range = await repo.getRange(
      const LocalDate(19721),
      const LocalDate(19723),
    );
    expect(
      range.map((item) => item.date.daysSinceEpoch),
      [19721, 19722, 19723],
    );
  });

  test('returns every day', () async {
    await repo.replaceAll([stats(1), stats(2)]);
    expect(await repo.getAll(), hasLength(2));
  });

  test('returns null last active date for an empty table', () async {
    expect(await repo.getLastActiveDate(), isNull);
  });

  test('returns the latest active day', () async {
    await repo.replaceAll([stats(10), stats(11), stats(12)]);

    expect(await repo.getLastActiveDate(), const LocalDate(12));
  });

  test('ignores days without answers', () async {
    await repo.replaceAll([
      stats(10),
      stats(12, newWords: 0, reviews: 0),
      stats(11),
    ]);

    expect(await repo.getLastActiveDate(), const LocalDate(11));
  });

  test('replaces all days', () async {
    await repo.replaceAll([stats(1), stats(2)]);

    await repo.replaceAll([stats(3)]);

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.date.daysSinceEpoch, 3);
  });
}
