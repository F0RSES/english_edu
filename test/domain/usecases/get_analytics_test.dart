import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/get_analytics.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_stats_repository.dart';
import 'fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now);

Word word(int id) =>
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id');

WordProgress progressOf(
  int id,
  WordStatus status, {
  int lapses = 0,
  DateTime? firstSeenAt,
}) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: 2500,
    intervalDays: 1,
    repetitions: 1,
    lapses: lapses,
    dueAt: now,
  ),
  status: status,
  firstSeenAt: firstSeenAt ?? now,
);

DailyStats statsOf(LocalDate date, {int answers = 1}) => DailyStats(
  date: date,
  newWordsStudied: answers,
  reviewsCompleted: 0,
  xpGained: answers * 10,
  correctAnswers: answers,
);

GetAnalytics analyticsOf({
  List<Word> words = const [],
  List<WordProgress> progress = const [],
  List<DailyStats> stats = const [],
}) => GetAnalytics(
  words: FakeWordRepository(words),
  progress: FakeProgressRepository(progress),
  stats: FakeStatsRepository(stats),
  clock: () => now,
);

void main() {
  test('counts statuses and treats words without progress as new', () async {
    final analytics = await analyticsOf(
      words: [word(1), word(2), word(3), word(4), word(5), word(6)],
      progress: [
        progressOf(1, WordStatus.mastered),
        progressOf(2, WordStatus.learning),
        progressOf(3, WordStatus.newWord),
      ],
    ).call();

    expect(analytics.totalWords, 6);
    expect(analytics.masteredCount, 1);
    expect(analytics.learningCount, 1);
    expect(analytics.newCount, 4);
  });

  test('keeps at most five hardest words ordered by lapses', () async {
    final analytics = await analyticsOf(
      words: [for (var id = 1; id <= 7; id++) word(id)],
      progress: [
        progressOf(1, WordStatus.learning, lapses: 1),
        progressOf(2, WordStatus.learning, lapses: 5),
        progressOf(3, WordStatus.learning, lapses: 2),
        progressOf(4, WordStatus.learning, lapses: 9),
        progressOf(5, WordStatus.learning, lapses: 3),
        progressOf(6, WordStatus.learning, lapses: 4),
        progressOf(7, WordStatus.learning),
      ],
    ).call();

    expect(
      [for (final item in analytics.hardestWords) item.word.id.value],
      [4, 2, 6, 5, 3],
    );
    expect(analytics.hardestWords.first.lapses, 9);
  });

  test('returns the last seven days of stats', () async {
    final analytics = await analyticsOf(
      words: [word(1)],
      stats: [
        statsOf(today.addDays(-8)),
        for (var offset = 6; offset >= 0; offset--)
          statsOf(today.addDays(-offset)),
      ],
    ).call();

    expect(analytics.last7Days, hasLength(7));
    expect(analytics.last7Days.first.date, today.addDays(-6));
    expect(analytics.last7Days.last.date, today);
  });

  test('fills empty days so the window always has seven entries', () async {
    // В БД только один день — окно всё равно должно быть полным.
    final analytics = await analyticsOf(
      words: [word(1)],
      stats: [statsOf(today.addDays(-2), answers: 4)],
    ).call();

    expect(analytics.last7Days, hasLength(7));
    expect(analytics.last7Days.first.date, today.addDays(-6));
    expect(analytics.last7Days.last.date, today);
    // День с активностью сохранил данные, остальные — пустые.
    expect(analytics.last7Days[4].totalAnswers, 4);
    expect(analytics.last7Days[0].totalAnswers, 0);
    expect(analytics.last7Days[6].totalAnswers, 0);
  });

  test('projects the mastery date from the observed rate', () async {
    // 1 mastered из 6 за 4 дня → 5 оставшихся по 0.25/день → 20 дней.
    final analytics = await analyticsOf(
      words: [for (var id = 1; id <= 6; id++) word(id)],
      progress: [
        progressOf(
          1,
          WordStatus.mastered,
          firstSeenAt: now.subtract(const Duration(days: 4)),
        ),
        progressOf(
          2,
          WordStatus.learning,
          firstSeenAt: now.subtract(const Duration(days: 4)),
        ),
      ],
    ).call();

    expect(analytics.projectedMasteryDate, today.addDays(20));
  });

  test('does not project without mastered words', () async {
    final analytics = await analyticsOf(
      words: [word(1), word(2)],
      progress: [progressOf(1, WordStatus.learning)],
    ).call();

    expect(analytics.projectedMasteryDate, isNull);
  });

  test('ignores progress left from deleted words', () async {
    final analytics = await analyticsOf(
      words: [word(1)],
      progress: [
        progressOf(1, WordStatus.learning),
        progressOf(99, WordStatus.mastered, lapses: 7),
      ],
    ).call();

    expect(analytics.totalWords, 1);
    expect(analytics.masteredCount, 0);
    expect(analytics.learningCount, 1);
    expect(analytics.hardestWords, isEmpty);
  });
}
