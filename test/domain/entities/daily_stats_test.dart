import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

void main() {
  const date = LocalDate(19858);

  group('DailyStats', () {
    test('empty has zero counters and zero accuracy', () {
      final stats = DailyStats.empty(date);
      expect(stats.date, date);
      expect(stats.newWordsStudied, 0);
      expect(stats.reviewsCompleted, 0);
      expect(stats.xpGained, 0);
      expect(stats.correctAnswers, 0);
      expect(stats.totalAnswers, 0);
      expect(stats.accuracy, 0.0);
    });

    test('computes totalAnswers as new words plus reviews', () {
      const stats = DailyStats(
        date: date,
        newWordsStudied: 4,
        reviewsCompleted: 6,
        xpGained: 30,
        correctAnswers: 5,
      );
      expect(stats.totalAnswers, 10);
      expect(stats.accuracy, 0.5);
    });

    test('keeps accuracy at zero when there are no answers', () {
      final stats = DailyStats.empty(date).copyWith(correctAnswers: 0);
      expect(stats.totalAnswers, 0);
      expect(stats.accuracy, 0.0);
    });

    test('rejects negative counters', () {
      expect(
        () => DailyStats(
          date: date,
          newWordsStudied: -1,
          reviewsCompleted: 0,
          xpGained: 0,
          correctAnswers: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DailyStats(
          date: date,
          newWordsStudied: 0,
          reviewsCompleted: -1,
          xpGained: 0,
          correctAnswers: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DailyStats(
          date: date,
          newWordsStudied: 0,
          reviewsCompleted: 0,
          xpGained: -1,
          correctAnswers: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DailyStats(
          date: date,
          newWordsStudied: 0,
          reviewsCompleted: 0,
          xpGained: 0,
          correctAnswers: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith replaces only the given fields', () {
      final updated = DailyStats.empty(date).copyWith(
        reviewsCompleted: 3,
        xpGained: 12,
      );
      expect(updated.reviewsCompleted, 3);
      expect(updated.xpGained, 12);
      expect(updated.newWordsStudied, 0);
      expect(updated.date, date);
    });

    test('copyWith without arguments returns an equal record', () {
      final stats = DailyStats.empty(date);
      expect(stats.copyWith(), equals(stats));
    });

    test('is equal and has the same hash for equal fields', () {
      final a = DailyStats.empty(date);
      final b = DailyStats.empty(date);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when a single counter differs', () {
      final a = DailyStats.empty(date);
      expect(a, isNot(equals(a.copyWith(xpGained: 1))));
    });
  });
}
