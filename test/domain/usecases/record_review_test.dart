import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/srs/sm2_srs_calculator.dart';
import 'package:english_edu/domain/srs/srs_calculator.dart';
import 'package:english_edu/domain/usecases/record_review.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/domain/value_objects/xp_rules.dart';
import 'package:test/test.dart';

import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_review_log_repository.dart';
import 'fakes/fake_srs_calculator.dart';
import 'fakes/fake_stats_repository.dart';
import 'fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word(int id) => Word(
      id: WordId(id),
      term: 'term$id',
      translation: 'перевод$id',
    );

WordProgress seeded(
  int id, {
  required int repetitions,
  int lapses = 0,
  int interval = 1,
  WordStatus status = WordStatus.learning,
}) =>
    WordProgress(
      wordId: WordId(id),
      cardState: CardState(
        easePermille: 2500,
        intervalDays: interval,
        repetitions: repetitions,
        lapses: lapses,
        dueAt: now,
      ),
      status: status,
      firstSeenAt: now.subtract(const Duration(days: 10)),
    );

final class Harness {
  Harness({
    List<Word>? seedWords,
    List<WordProgress>? seedProgress,
    List<DailyStats>? seedStats,
    SrsCalculator? srs,
  })  : words = FakeWordRepository(seedWords ?? [word(1)]),
        progress = FakeProgressRepository(seedProgress ?? const []),
        stats = FakeStatsRepository(seedStats ?? const []),
        srs = srs ?? const FakeSrsCalculator() {
    useCase = RecordReview(
      progress: progress,
      reviewLog: logs,
      stats: stats,
      words: words,
      srs: this.srs,
      nextLogId: () => ReviewLogId(logCounter++),
      clock: () => now,
    );
  }

  static final today = LocalDate.fromDateTime(now.toLocal());

  final FakeWordRepository words;
  final FakeProgressRepository progress;
  final FakeStatsRepository stats;
  final FakeReviewLogRepository logs = FakeReviewLogRepository();
  final SrsCalculator srs;
  int logCounter = 0;
  late final RecordReview useCase;
}

void main() {
  group('RecordReview', () {
    test('rejects an unknown word', () async {
      final harness = Harness(seedWords: const []);
      await expectLater(
        harness.useCase(const WordId(1), ReviewGrade.good),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('creates progress on the first answer', () async {
      final harness = Harness();
      await harness.useCase(const WordId(1), ReviewGrade.good);

      final saved = await harness.progress.getByWordId(const WordId(1));
      expect(saved, isNotNull);
      expect(saved!.firstSeenAt, now);
      expect(saved.lastReviewedAt, now);
      expect(saved.status, WordStatus.learning);
    });

    test('keeps firstSeenAt on the second answer', () async {
      final harness = Harness(seedProgress: [seeded(1, repetitions: 3)]);
      await harness.useCase(const WordId(1), ReviewGrade.good);

      final saved = await harness.progress.getByWordId(const WordId(1));
      expect(saved!.firstSeenAt, now.subtract(const Duration(days: 10)));
      expect(saved.cardState.repetitions, 4);
    });

    test('returns the same state that was stored', () async {
      final harness = Harness();
      final returned = await harness.useCase(
        const WordId(1),
        ReviewGrade.hard,
      );
      final saved = await harness.progress.getByWordId(const WordId(1));
      expect(saved!.cardState, returned.newCardState);
    });
    test('counts a successful answer as correct', () async {
      final harness = Harness();
      await harness.useCase(const WordId(1), ReviewGrade.good);

      final stats = await harness.stats.getForDate(Harness.today);
      expect(stats, isNotNull);
      expect(stats!.reviewsCompleted, 1);
      expect(stats.correctAnswers, 1);
    });

    test('does not count again as correct but counts the review', () async {
      final harness = Harness();
      await harness.useCase(const WordId(1), ReviewGrade.again);

      final stats = await harness.stats.getForDate(Harness.today);
      expect(stats!.reviewsCompleted, 1);
      expect(stats.correctAnswers, 0);
    });

    test('xp and correctness match XpRules for every grade', () async {
      for (final grade in ReviewGrade.values) {
        final harness = Harness();
        final outcome = await harness.useCase(const WordId(1), grade);
        expect(outcome.xpGained, XpRules.forGrade(grade), reason: '$grade');
        expect(outcome.isCorrect, XpRules.isCorrect(grade), reason: '$grade');
      }
    });

    test('awards xp per grade', () async {
      const expected = {
        ReviewGrade.again: 0,
        ReviewGrade.hard: 5,
        ReviewGrade.good: 10,
        ReviewGrade.easy: 15,
      };
      for (final entry in expected.entries) {
        final harness = Harness();
        await harness.useCase(const WordId(1), entry.key);
        final stats = await harness.stats.getForDate(Harness.today);
        expect(stats!.xpGained, entry.value, reason: '${entry.key}');
      }
    });

    test('appends a log with previous and new card states', () async {
      final initial = seeded(1, repetitions: 2);
      final harness = Harness(seedProgress: [initial]);
      final next = await harness.useCase(const WordId(1), ReviewGrade.good);

      final entries = await harness.logs.getByWordId(const WordId(1));
      expect(entries, hasLength(1));
      expect(entries.single.id, const ReviewLogId(0));
      expect(entries.single.reviewedAt, now);
      expect(entries.single.grade, ReviewGrade.good);
      expect(entries.single.previousCardState, initial.cardState);
      expect(entries.single.newCardState, next.newCardState);
    });

    test('keeps learning after a lapse instead of returning to newWord',
        () async {
      final harness = Harness(seedProgress: [seeded(1, repetitions: 2)]);
      await harness.useCase(const WordId(1), ReviewGrade.again);

      final saved = await harness.progress.getByWordId(const WordId(1));
      expect(saved!.cardState.repetitions, 0);
      expect(saved.status, WordStatus.learning);
    });

    test('derives mastered when reps and interval pass the thresholds',
        () async {
      final harness = Harness(
        srs: const Sm2SrsCalculator(),
        seedProgress: [seeded(1, repetitions: 4, interval: 60)],
      );
      await harness.useCase(const WordId(1), ReviewGrade.good);

      final saved = await harness.progress.getByWordId(const WordId(1));
      expect(saved!.cardState.repetitions, 5);
      expect(saved.cardState.intervalDays, 150);
      expect(saved.status, WordStatus.mastered);
    });

    test('stays learning below the interval threshold', () async {
      final harness = Harness(
        srs: const Sm2SrsCalculator(),
        seedProgress: [seeded(1, repetitions: 4)],
      );
      await harness.useCase(const WordId(1), ReviewGrade.good);

      final saved = await harness.progress.getByWordId(const WordId(1));
      expect(saved!.cardState.repetitions, 5);
      expect(saved.cardState.intervalDays, 3);
      expect(saved.status, WordStatus.learning);
    });

    test('keeps a lapsing word in learning', () async {
      final harness = Harness(
        seedProgress: [seeded(1, repetitions: 4, lapses: 2)],
      );
      await harness.useCase(const WordId(1), ReviewGrade.good);

      final saved = await harness.progress.getByWordId(const WordId(1));
      expect(saved!.cardState.repetitions, 5);
      expect(saved.status, WordStatus.learning);
    });
  });

  group('RecordReview with real Sm2SrsCalculator', () {
    test('first good answer schedules tomorrow', () async {
      final harness = Harness(srs: const Sm2SrsCalculator());
      final next = await harness.useCase(const WordId(1), ReviewGrade.good);

      expect(next.newCardState.repetitions, 1);
      expect(next.newCardState.intervalDays, 1);
      expect(next.newCardState.easePermille, 2500);
      expect(next.newCardState.dueAt, now.add(const Duration(days: 1)));
    });

    test('two good answers move to six days', () async {
      final harness = Harness(srs: const Sm2SrsCalculator());
      await harness.useCase(const WordId(1), ReviewGrade.good);
      final next = await harness.useCase(const WordId(1), ReviewGrade.good);

      expect(next.newCardState.repetitions, 2);
      expect(next.newCardState.intervalDays, 6);
      expect(next.newCardState.dueAt, now.add(const Duration(days: 6)));
    });

    test('good then good then again resets the card', () async {
      final harness = Harness(srs: const Sm2SrsCalculator());
      await harness.useCase(const WordId(1), ReviewGrade.good);
      await harness.useCase(const WordId(1), ReviewGrade.good);
      final next = await harness.useCase(const WordId(1), ReviewGrade.again);

      expect(next.newCardState.repetitions, 0);
      expect(next.newCardState.intervalDays, 1);
      expect(next.newCardState.lapses, 1);
      expect(next.newCardState.easePermille, 1700);
    });

    test('uses the injected calculator rather than a default', () async {
      final withFake = Harness();
      await withFake.useCase(const WordId(1), ReviewGrade.good);
      final fakeNext = await withFake.useCase(
        const WordId(1),
        ReviewGrade.good,
      );

      final withSm2 = Harness(srs: const Sm2SrsCalculator());
      await withSm2.useCase(const WordId(1), ReviewGrade.good);
      final sm2Next = await withSm2.useCase(const WordId(1), ReviewGrade.good);

      expect(fakeNext.newCardState.intervalDays, 2);
      expect(sm2Next.newCardState.intervalDays, 6);
    });

    test('five goods in a row walk 1/6/15/38/95 and reach mastered', () async {
      final harness = Harness(srs: const Sm2SrsCalculator());
      const steps = [
        (reps: 1, interval: 1, status: WordStatus.learning),
        (reps: 2, interval: 6, status: WordStatus.learning),
        (reps: 3, interval: 15, status: WordStatus.learning),
        (reps: 4, interval: 38, status: WordStatus.learning),
        (reps: 5, interval: 95, status: WordStatus.mastered),
      ];

      for (final step in steps) {
        final next = await harness.useCase(const WordId(1), ReviewGrade.good);
        expect(next.newCardState.repetitions, step.reps);
        expect(next.newCardState.intervalDays, step.interval);
        expect(next.newCardState.dueAt, now.add(Duration(days: step.interval)));
        expect(next.newCardState.lapses, 0);

        final saved = await harness.progress.getByWordId(const WordId(1));
        expect(saved!.status, step.status, reason: 'step ${step.reps}');
      }
    });

    test('a lapse resets the interval and keeps ease above the floor',
        () async {
      final harness = Harness(srs: const Sm2SrsCalculator());
      for (var answer = 0; answer < 3; answer++) {
        await harness.useCase(const WordId(1), ReviewGrade.good);
      }

      final before = await harness.progress.getByWordId(const WordId(1));
      expect(before!.cardState.repetitions, 3);
      expect(before.cardState.intervalDays, 15);
      expect(before.cardState.easePermille, 2500);
      expect(before.status, WordStatus.learning);

      final next = await harness.useCase(const WordId(1), ReviewGrade.again);
      expect(next.newCardState.repetitions, 0);
      expect(next.newCardState.intervalDays, 1);
      expect(next.newCardState.lapses, 1);
      expect(next.newCardState.easePermille, 1700);
      expect(next.newCardState.dueAt, now.add(const Duration(days: 1)));

      final after = await harness.progress.getByWordId(const WordId(1));
      expect(after!.status, WordStatus.learning);
    });

    test('four goods give interval 38 but stay learning', () async {
      final harness = Harness(srs: const Sm2SrsCalculator());
      for (var answer = 0; answer < 4; answer++) {
        await harness.useCase(const WordId(1), ReviewGrade.good);
      }

      final saved = await harness.progress.getByWordId(const WordId(1));
      expect(saved!.cardState.repetitions, 4);
      expect(saved.cardState.intervalDays, 38);
      expect(saved.status, WordStatus.learning);
    });

    test('a word with two lapses can still reach mastered', () async {
      final harness = Harness(srs: const Sm2SrsCalculator());

      Future<CardState> answer(ReviewGrade grade) async =>
          (await harness.useCase(const WordId(1), grade)).newCardState;
      Future<WordProgress> reload() async =>
          (await harness.progress.getByWordId(const WordId(1)))!;

      for (var i = 0; i < 5; i++) {
        await answer(ReviewGrade.good);
      }
      var state = await reload();
      expect(state.cardState.repetitions, 5);
      expect(state.cardState.intervalDays, 95);
      expect(state.status, WordStatus.mastered);

      await answer(ReviewGrade.again);
      state = await reload();
      expect(state.cardState.repetitions, 0);
      expect(state.cardState.lapses, 1);
      expect(state.cardState.easePermille, 1700);

      // Ease 1700: интервалы 1, 6, 10, 17, 29.
      for (var i = 0; i < 5; i++) {
        await answer(ReviewGrade.good);
      }
      state = await reload();
      expect(state.cardState.repetitions, 5);
      expect(state.cardState.intervalDays, 29);
      expect(state.status, WordStatus.mastered);

      await answer(ReviewGrade.again);
      state = await reload();
      expect(state.cardState.lapses, 2);
      expect(state.cardState.easePermille, 1300);

      // Ease на полу 1300: 1, 6, 8, 10, 13 — порог 21 ещё не пройден.
      for (var i = 0; i < 5; i++) {
        await answer(ReviewGrade.good);
      }
      state = await reload();
      expect(state.cardState.repetitions, 5);
      expect(state.cardState.intervalDays, 13);
      expect(state.status, WordStatus.learning);

      // 17, 22 — порог пройден на седьмом ответе, lapses=2 не мешает.
      await answer(ReviewGrade.good);
      await answer(ReviewGrade.good);
      state = await reload();
      expect(state.cardState.repetitions, 7);
      expect(state.cardState.intervalDays, 22);
      expect(state.cardState.lapses, 2);
      expect(state.status, WordStatus.mastered);
    });
  });
}
