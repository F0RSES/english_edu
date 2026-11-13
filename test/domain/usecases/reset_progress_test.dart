import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/reset_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_review_log_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_stats_repository.dart';
import 'fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word(int id) =>
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id');

WordProgress progress(int id) => WordProgress(
  wordId: WordId(id),
  cardState: CardState.initial(now),
  status: WordStatus.learning,
  firstSeenAt: now,
);

ReviewLog log(int id) => ReviewLog(
  id: ReviewLogId(id),
  wordId: const WordId(1),
  reviewedAt: now,
  grade: ReviewGrade.good,
  previousCardState: CardState.initial(now),
  newCardState: CardState.initial(now),
);

DailyStats stats(int daysSinceEpoch) => DailyStats(
  date: LocalDate(daysSinceEpoch),
  newWordsStudied: 1,
  reviewsCompleted: 0,
  xpGained: 10,
  correctAnswers: 1,
);

void main() {
  test('clears progress, logs and stats', () async {
    final progressRepo = FakeProgressRepository([progress(1)]);
    final logRepo = FakeReviewLogRepository([log(1)]);
    final statsRepo = FakeStatsRepository([stats(20000)]);
    final reset = ResetProgress(
      progress: progressRepo,
      reviewLog: logRepo,
      stats: statsRepo,
    );

    await reset();

    expect(await progressRepo.getAll(), isEmpty);
    expect(await logRepo.getAll(), isEmpty);
    expect(await statsRepo.getAll(), isEmpty);
  });

  test('keeps words untouched', () async {
    final words = FakeWordRepository([word(1), word(2)]);
    final reset = ResetProgress(
      progress: FakeProgressRepository([progress(1)]),
      reviewLog: FakeReviewLogRepository([log(1)]),
      stats: FakeStatsRepository([stats(20000)]),
    );

    await reset();

    expect(await words.getAll(), hasLength(2));
  });

  test('keeps settings untouched', () async {
    final settings = FakeSettingsRepository(
      const UserSettings(dailyNewLimit: 7),
    );
    final reset = ResetProgress(
      progress: FakeProgressRepository([progress(1)]),
      reviewLog: FakeReviewLogRepository([log(1)]),
      stats: FakeStatsRepository([stats(20000)]),
    );

    await reset();

    expect((await settings.get()).dailyNewLimit, 7);
  });
}
