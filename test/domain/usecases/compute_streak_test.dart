import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/usecases/compute_streak.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

import 'fakes/fake_stats_repository.dart';

final today = LocalDate.fromDateTime(DateTime.utc(2024, 5, 15));

DailyStats active(LocalDate date) => DailyStats(
  date: date,
  newWordsStudied: 1,
  reviewsCompleted: 2,
  xpGained: 3,
  correctAnswers: 3,
);

ComputeStreak streakOf(List<DailyStats> stats) => ComputeStreak(
  stats: FakeStatsRepository(stats),
  clock: () => DateTime.utc(2024, 5, 15, 12),
);

void main() {
  group('ComputeStreak', () {
    test('returns zero for an empty history', () async {
      final info = await streakOf(const []).call();
      expect(info.count, 0);
      expect(info.lastActiveLocalDate, isNull);
    });

    test('counts a single active day today', () async {
      final info = await streakOf([active(today)]).call();
      expect(info.count, 1);
      expect(info.lastActiveLocalDate, today);
    });

    test('counts three consecutive days', () async {
      final info = await streakOf([
        active(today),
        active(today.addDays(-1)),
        active(today.addDays(-2)),
      ]).call();
      expect(info.count, 3);
      expect(info.lastActiveLocalDate, today);
    });

    test('stops at a gap yesterday', () async {
      final info = await streakOf([active(today), active(today.addDays(-2))])
          .call();
      expect(info.count, 1);
      expect(info.lastActiveLocalDate, today);
    });

    test('stops two days back', () async {
      final info = await streakOf([
        active(today),
        active(today.addDays(-1)),
        active(today.addDays(-3)),
      ]).call();
      expect(info.count, 2);
      expect(info.lastActiveLocalDate, today);
    });

    test('reports zero when today is empty but yesterday is active', () async {
      final info = await streakOf([active(today.addDays(-1))]).call();
      expect(info.count, 0);
      expect(info.lastActiveLocalDate, today.addDays(-1));
    });

    test('ignores days with zero answers', () async {
      final quiet = DailyStats.empty(today.addDays(-1));
      final info = await streakOf([active(today), quiet]).call();
      expect(info.count, 1);
      expect(info.lastActiveLocalDate, today);
    });

    test('keeps a long streak of 400 days', () async {
      final long = [
        for (var offset = 0; offset < 400; offset++)
          active(today.addDays(-offset)),
      ];
      final info = await streakOf(long).call();
      expect(info.count, 400);
      expect(info.lastActiveLocalDate, today);
    });

    test('ignores activity dated in the future', () async {
      final info = await streakOf([active(today.addDays(1))]).call();
      expect(info.count, 0);
      expect(info.lastActiveLocalDate, isNull);
    });

    test('uses the local calendar date of now', () async {
      // 23:30 UTC: к востоку от UTC это уже следующий локальный день.
      // Если бы streak брал UTC-дату, на таком хосте тест бы упал.
      final instant = DateTime.utc(2024, 5, 15, 23, 30);
      final localDay = LocalDate.fromDateTime(instant.toLocal());
      final info = await ComputeStreak(
        stats: FakeStatsRepository([active(localDay)]),
        clock: () => instant,
      ).call();

      expect(info.count, 1);
      expect(info.lastActiveLocalDate, localDay);
    });
  });
}
