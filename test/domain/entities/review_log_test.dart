import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

void main() {
  final reviewedAt = DateTime.utc(2024, 3, 1, 10);
  final previous = CardState.initial(DateTime.utc(2024, 3));

  ReviewLog createLog() => ReviewLog(
        id: const ReviewLogId(1),
        wordId: const WordId(2),
        reviewedAt: reviewedAt,
        grade: ReviewGrade.good,
        previousCardState: previous,
        newCardState: previous.copyWith(intervalDays: 1, repetitions: 1),
      );

  group('ReviewLog', () {
    test('keeps every given value', () {
      final log = createLog();
      expect(log.id, const ReviewLogId(1));
      expect(log.wordId, const WordId(2));
      expect(log.reviewedAt, reviewedAt);
      expect(log.grade, ReviewGrade.good);
      expect(log.previousCardState, previous);
      expect(log.newCardState.intervalDays, 1);
      expect(log.newCardState.repetitions, 1);
    });

    test('rejects a non-UTC reviewedAt', () {
      expect(
        () => ReviewLog(
          id: const ReviewLogId(1),
          wordId: const WordId(2),
          reviewedAt: DateTime(2024, 3),
          grade: ReviewGrade.good,
          previousCardState: previous,
          newCardState: previous,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('is equal and has the same hash for equal fields', () {
      expect(createLog(), equals(createLog()));
      expect(createLog().hashCode, createLog().hashCode);
    });

    test('differs when the grade differs', () {
      final other = ReviewLog(
        id: const ReviewLogId(1),
        wordId: const WordId(2),
        reviewedAt: reviewedAt,
        grade: ReviewGrade.again,
        previousCardState: previous,
        newCardState: previous,
      );
      expect(createLog(), isNot(equals(other)));
    });

    test('renders id, word, grade and timestamp', () {
      expect(
        createLog().toString(),
        'ReviewLog(1, word=2, grade=ReviewGrade.good, '
        'at=2024-03-01T10:00:00.000Z)',
      );
    });
  });
}
