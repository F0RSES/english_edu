import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2024, 3, 1, 10);

  group('WordProgress', () {
    test('newWord starts from the initial card state', () {
      final progress = WordProgress.newWord(wordId: const WordId(1), now: now);
      expect(progress.wordId, const WordId(1));
      expect(progress.status, WordStatus.newWord);
      expect(progress.cardState, CardState.initial(now));
      expect(progress.firstSeenAt, now);
      expect(progress.firstSeenAt.isUtc, isTrue);
      expect(progress.lastReviewedAt, isNull);
    });

    test('newWord converts a local timestamp to UTC', () {
      final local = DateTime(2024, 3, 1, 10);
      final progress = WordProgress.newWord(
        wordId: const WordId(1),
        now: local,
      );
      expect(progress.firstSeenAt.isUtc, isTrue);
      expect(progress.firstSeenAt, local.toUtc());
    });

    test('rejects a non-UTC firstSeenAt', () {
      expect(
        () => WordProgress(
          wordId: const WordId(1),
          cardState: CardState.initial(now),
          status: WordStatus.newWord,
          firstSeenAt: DateTime(2024, 3),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a non-UTC lastReviewedAt', () {
      expect(
        () => WordProgress(
          wordId: const WordId(1),
          cardState: CardState.initial(now),
          status: WordStatus.learning,
          firstSeenAt: now,
          lastReviewedAt: DateTime(2024, 3, 2),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('is equal and has the same hash for equal fields', () {
      final a = WordProgress.newWord(wordId: const WordId(1), now: now);
      final b = WordProgress.newWord(wordId: const WordId(1), now: now);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when the status differs', () {
      final a = WordProgress.newWord(wordId: const WordId(1), now: now);
      expect(a, isNot(equals(a.copyWith(status: WordStatus.learning))));
    });

    test('copyWith sets and clears lastReviewedAt', () {
      final progress = WordProgress.newWord(
        wordId: const WordId(1),
        now: now,
      );
      final reviewed = progress.copyWith(lastReviewedAt: now);
      expect(reviewed.lastReviewedAt, now);
      expect(reviewed.copyWith(lastReviewedAt: null).lastReviewedAt, isNull);
    });

    test('copyWith without arguments returns an equal record', () {
      final progress = WordProgress.newWord(
        wordId: const WordId(1),
        now: now,
      );
      expect(progress.copyWith(), equals(progress));
    });
  });
}
