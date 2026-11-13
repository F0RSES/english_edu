import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/undo_last_review.dart';
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
import 'fakes/fake_stats_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
const wordId = WordId(1);

WordProgress progress() => WordProgress(
  wordId: wordId,
  cardState: CardState.initial(now).copyWith(intervalDays: 6, repetitions: 2),
  status: WordStatus.learning,
  firstSeenAt: now,
  lastReviewedAt: now,
);

ReviewLog log(int id) => ReviewLog(
  id: ReviewLogId(id),
  wordId: wordId,
  reviewedAt: now,
  grade: ReviewGrade.good,
  previousCardState: CardState.initial(now),
  newCardState: CardState.initial(now).copyWith(intervalDays: 6),
);

void main() {
  late FakeProgressRepository progressRepo;
  late FakeReviewLogRepository logRepo;
  late FakeStatsRepository statsRepo;
  late UndoLastReview undo;

  setUp(() {
    progressRepo = FakeProgressRepository([progress()]);
    logRepo = FakeReviewLogRepository([log(1)]);
    statsRepo = FakeStatsRepository();
    undo = UndoLastReview(
      progress: progressRepo,
      reviewLog: logRepo,
      stats: statsRepo,
    );
  });

  test('removes the last log and restores the previous card state', () async {
    expect(await undo(wordId), isTrue);

    expect(await logRepo.getAll(), isEmpty);
    final restored = await progressRepo.getByWordId(wordId);
    expect(restored!.cardState.intervalDays, 0);
    expect(restored.cardState.repetitions, 0);
  });

  test('clears lastReviewedAt when no reviews remain', () async {
    await undo(wordId);

    final restored = await progressRepo.getByWordId(wordId);
    expect(restored!.lastReviewedAt, isNull);
    expect(restored.status, WordStatus.newWord);
  });

  test('keeps the reviewed state when earlier logs remain', () async {
    logRepo = FakeReviewLogRepository([log(1), log(2)]);
    undo = UndoLastReview(
      progress: progressRepo,
      reviewLog: logRepo,
      stats: statsRepo,
    );

    await undo(wordId);

    final restored = await progressRepo.getByWordId(wordId);
    expect(restored!.lastReviewedAt, now);
    expect(restored.status, WordStatus.learning);
    expect(await logRepo.getAll(), hasLength(1));
  });

  test('returns false when there is nothing to undo', () async {
    logRepo = FakeReviewLogRepository();
    undo = UndoLastReview(
      progress: progressRepo,
      reviewLog: logRepo,
      stats: statsRepo,
    );

    expect(await undo(wordId), isFalse);
  });

  test('reverts daily stats for every grade', () async {
    for (final grade in ReviewGrade.values) {
      final day = LocalDate.fromDateTime(now.toLocal());
      final statsRepo = FakeStatsRepository([
        DailyStats(
          date: day,
          newWordsStudied: 0,
          reviewsCompleted: 1,
          xpGained: XpRules.forGrade(grade),
          correctAnswers: XpRules.isCorrect(grade) ? 1 : 0,
        ),
      ]);
      final localProgress = FakeProgressRepository([progress()]);
      final localLogs = FakeReviewLogRepository([
        ReviewLog(
          id: const ReviewLogId(1),
          wordId: wordId,
          reviewedAt: now,
          grade: grade,
          previousCardState: CardState.initial(now),
          newCardState: CardState.initial(now),
        ),
      ]);

      final result = await UndoLastReview(
        progress: localProgress,
        reviewLog: localLogs,
        stats: statsRepo,
      )(wordId);

      expect(result, isTrue, reason: '$grade');
      final stats = await statsRepo.getForDate(day);
      expect(stats!.reviewsCompleted, 0, reason: '$grade');
      expect(stats.xpGained, 0, reason: '$grade');
      expect(stats.correctAnswers, 0, reason: '$grade');
    }
  });

  test('clamps stats to zero when they were edited manually', () async {
    final day = LocalDate.fromDateTime(now.toLocal());
    statsRepo = FakeStatsRepository([DailyStats.empty(day)]);
    undo = UndoLastReview(
      progress: progressRepo,
      reviewLog: logRepo,
      stats: statsRepo,
    );

    await undo(wordId);

    final stats = await statsRepo.getForDate(day);
    expect(stats!.reviewsCompleted, 0);
    expect(stats.xpGained, 0);
    expect(stats.correctAnswers, 0);
  });
}
