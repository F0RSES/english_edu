import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:meta/meta.dart';

/// Aggregated counters for one local day. Derived from review logs.
@immutable
final class DailyStats {
  /// Creates counters for [date]; all counters must be non-negative.
  const DailyStats({
    required this.date,
    required this.newWordsStudied,
    required this.reviewsCompleted,
    required this.xpGained,
    required this.correctAnswers,
  })  : assert(newWordsStudied >= 0, 'newWordsStudied must be >= 0'),
        assert(reviewsCompleted >= 0, 'reviewsCompleted must be >= 0'),
        assert(xpGained >= 0, 'xpGained must be >= 0'),
        assert(correctAnswers >= 0, 'correctAnswers must be >= 0');

  /// Counters of a day without any activity.
  factory DailyStats.empty(LocalDate date) => DailyStats(
        date: date,
        newWordsStudied: 0,
        reviewsCompleted: 0,
        xpGained: 0,
        correctAnswers: 0,
      );

  /// Local day these counters belong to.
  final LocalDate date;

  /// New words shown for the first time.
  final int newWordsStudied;

  /// Reviews of already known words.
  final int reviewsCompleted;

  /// Experience points earned.
  final int xpGained;

  /// Answers graded as successful.
  final int correctAnswers;

  /// Number of answers in the day: new words plus reviews.
  int get totalAnswers => newWordsStudied + reviewsCompleted;

  /// Share of successful answers, 0.0 when there were none.
  ///
  /// Approximation for the MVP: it is correct only while every answer is
  /// counted in [correctAnswers]; the exact definition belongs to the SRS
  /// spec of Phase 3.
  double get accuracy =>
      totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;

  /// Returns a copy with the given fields replaced.
  DailyStats copyWith({
    LocalDate? date,
    int? newWordsStudied,
    int? reviewsCompleted,
    int? xpGained,
    int? correctAnswers,
  }) =>
      DailyStats(
        date: date ?? this.date,
        newWordsStudied: newWordsStudied ?? this.newWordsStudied,
        reviewsCompleted: reviewsCompleted ?? this.reviewsCompleted,
        xpGained: xpGained ?? this.xpGained,
        correctAnswers: correctAnswers ?? this.correctAnswers,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStats &&
          date == other.date &&
          newWordsStudied == other.newWordsStudied &&
          reviewsCompleted == other.reviewsCompleted &&
          xpGained == other.xpGained &&
          correctAnswers == other.correctAnswers;

  @override
  int get hashCode => Object.hash(
        date,
        newWordsStudied,
        reviewsCompleted,
        xpGained,
        correctAnswers,
      );

  @override
  String toString() => 'DailyStats($date, new: $newWordsStudied, '
      'reviews: $reviewsCompleted, xp: $xpGained, '
      'correct: $correctAnswers)';
}
