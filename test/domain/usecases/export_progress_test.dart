import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/export_progress.dart';
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
final today = LocalDate.fromDateTime(now.toLocal());

Word word(int id) =>
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id');

WordProgress progressOf(int id, WordStatus status) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: 2500,
    intervalDays: 1,
    repetitions: 1,
    lapses: 0,
    dueAt: now,
  ),
  status: status,
  firstSeenAt: now.subtract(const Duration(days: 5)),
);

ReviewLog logOf(int id) => ReviewLog(
  id: ReviewLogId(id),
  wordId: const WordId(1),
  reviewedAt: now.subtract(const Duration(hours: 1)),
  grade: ReviewGrade.good,
  previousCardState: CardState.initial(now),
  newCardState: CardState.initial(now),
);

ExportProgress exportOf({
  List<Word> seedWords = const [],
  List<WordProgress> seedProgress = const [],
  List<ReviewLog> seedLogs = const [],
  List<DailyStats> seedStats = const [],
  UserSettings? settings,
}) => ExportProgress(
  settings: FakeSettingsRepository(settings),
  progress: FakeProgressRepository(seedProgress),
  reviewLog: FakeReviewLogRepository(seedLogs),
  stats: FakeStatsRepository(seedStats),
  words: FakeWordRepository(seedWords),
  clock: () => now,
);

void main() {
  group('ExportProgress', () {
    test('returns an empty payload for empty repositories', () async {
      final payload = await exportOf().call();

      expect(payload.schemaVersion, 1);
      expect(payload.exportedAt, now);
      expect(payload.words, isEmpty);
      expect(payload.progress, isEmpty);
      expect(payload.logs, isEmpty);
      expect(payload.stats, isEmpty);
      expect(payload.settings, UserSettings.defaults());
    });

    test('collects words, progress of every status, logs and stats', () async {
      final payload = await exportOf(
        seedWords: [word(1), word(2), word(3)],
        seedProgress: [
          progressOf(1, WordStatus.newWord),
          progressOf(2, WordStatus.learning),
          progressOf(3, WordStatus.mastered),
        ],
        seedLogs: [logOf(1)],
        seedStats: [DailyStats.empty(today)],
      ).call();

      expect(payload.words, hasLength(3));
      expect(payload.progress, hasLength(3));
      expect(payload.progress, contains(progressOf(3, WordStatus.mastered)));
      expect(payload.logs, hasLength(1));
      expect(payload.stats, hasLength(1));
    });

    test('keeps settings from the repository', () async {
      final custom = UserSettings.defaults().copyWith(dailyNewLimit: 3);
      final payload = await exportOf(settings: custom).call();
      expect(payload.settings.dailyNewLimit, 3);
    });

    test('stamps exportedAt in UTC', () async {
      final payload = await exportOf().call();
      expect(payload.exportedAt.isUtc, isTrue);
    });

    test('includes a log written at the export instant', () async {
      final atNow = ReviewLog(
        id: const ReviewLogId(7),
        wordId: const WordId(1),
        reviewedAt: now,
        grade: ReviewGrade.good,
        previousCardState: CardState.initial(now),
        newCardState: CardState.initial(now),
      );
      final payload = await exportOf(seedLogs: [atNow]).call();
      expect(payload.logs, [atNow]);
    });
  });
}
