import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/get_today_queue.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word(int id, {CefrLevel level = CefrLevel.a1}) => Word(
  id: WordId(id),
  term: 'term$id',
  translation: 'перевод$id',
  level: level,
);

WordProgress dueProgress(int id, Duration offset) => WordProgress(
  wordId: WordId(id),
  cardState: CardState.initial(now.add(offset)),
  status: WordStatus.learning,
  firstSeenAt: now.add(const Duration(days: -30)),
);

WordProgress newProgress(int id, Duration seenAgo) => WordProgress(
  wordId: WordId(id),
  cardState: CardState.initial(now.add(const Duration(days: 1))),
  status: WordStatus.newWord,
  firstSeenAt: now.subtract(seenAgo),
);

GetTodayQueue queueOf({
  required List<Word> words,
  required List<WordProgress> progress,
  UserSettings? settings,
}) => GetTodayQueue(
  words: FakeWordRepository(words),
  progress: FakeProgressRepository(progress),
  settings: FakeSettingsRepository(settings),
  clock: () => now,
);

List<int> ids(List<Word> words) => [for (final item in words) item.id.value];

void main() {
  group('GetTodayQueue', () {
    test('returns an empty queue for empty repositories', () async {
      final queue = await queueOf(words: const [], progress: const []).call();
      expect(queue.due, isEmpty);
      expect(queue.newWords, isEmpty);
      expect(queue.length, 0);
    });

    test('splits due and new words and orders both', () async {
      final queue = await queueOf(
        words: [word(1), word(2), word(3), word(4), word(5)],
        progress: [
          dueProgress(2, const Duration(hours: -1)),
          dueProgress(1, const Duration(hours: -3)),
          dueProgress(3, const Duration(hours: -2)),
          newProgress(4, const Duration(days: 1)),
          newProgress(5, const Duration(days: 2)),
        ],
      ).call();

      expect(ids(queue.due), [1, 3, 2]);
      expect(ids(queue.newWords), [5, 4]);
      expect(queue.length, 5);
    });

    test('returns word content, not just ids', () async {
      final queue = await queueOf(
        words: [word(1), word(2)],
        progress: [dueProgress(2, const Duration(hours: -1))],
      ).call();

      expect(queue.due, [word(2)]);
      expect(queue.due.single.term, 'term2');
      expect(queue.due.single.translation, 'перевод2');
    });

    test('trims due words by dailyReviewLimit keeping the earliest', () async {
      final queue = await queueOf(
        words: [word(1), word(2), word(3)],
        progress: [
          dueProgress(1, const Duration(hours: -3)),
          dueProgress(2, const Duration(hours: -1)),
          dueProgress(3, const Duration(hours: -2)),
        ],
        settings: UserSettings.defaults().copyWith(dailyReviewLimit: 1),
      ).call();

      expect(ids(queue.due), [1]);
    });

    test('trims new words by dailyNewLimit keeping the earliest', () async {
      final queue = await queueOf(
        words: [word(1), word(2)],
        progress: [
          newProgress(1, const Duration(days: 1)),
          newProgress(2, const Duration(days: 2)),
        ],
        settings: UserSettings.defaults().copyWith(dailyNewLimit: 1),
      ).call();

      expect(ids(queue.newWords), [2]);
    });

    test('returns empty sections when both limits are zero', () async {
      final queue = await queueOf(
        words: [word(1), word(2)],
        progress: [
          dueProgress(1, const Duration(hours: -1)),
          newProgress(2, const Duration(days: 1)),
        ],
        settings: UserSettings.defaults().copyWith(
          dailyNewLimit: 0,
          dailyReviewLimit: 0,
        ),
      ).call();

      expect(queue.due, isEmpty);
      expect(queue.newWords, isEmpty);
    });

    test('skips progress without a matching word', () async {
      final queue = await queueOf(
        words: [word(1)],
        progress: [
          dueProgress(1, const Duration(hours: -1)),
          dueProgress(99, const Duration(hours: -2)),
        ],
      ).call();

      expect(ids(queue.due), [1]);
    });

    test('excludes newWord progress from due', () async {
      final fresh = WordProgress.newWord(wordId: const WordId(1), now: now);
      final queue = await queueOf(words: [word(1)], progress: [fresh]).call();

      expect(queue.due, isEmpty);
      expect(ids(queue.newWords), [1]);
    });

    test('never lists the same word id in both sections', () async {
      final queue = await queueOf(
        words: [word(1), word(2)],
        progress: [
          WordProgress.newWord(wordId: const WordId(1), now: now),
          dueProgress(2, const Duration(hours: -1)),
        ],
      ).call();

      expect(ids(queue.due), [2]);
      expect(ids(queue.newWords), [1]);
    });

    test('applies dailyReviewLimit after removing new words', () async {
      final queue = await queueOf(
        words: [word(1), word(2), word(3)],
        progress: [
          WordProgress.newWord(wordId: const WordId(1), now: now),
          dueProgress(2, const Duration(hours: -2)),
          dueProgress(3, const Duration(hours: -1)),
        ],
        settings: UserSettings.defaults().copyWith(dailyReviewLimit: 1),
      ).call();

      expect(ids(queue.due), [2]);
      expect(ids(queue.newWords), [1]);
    });

    test('word without progress appears in newWords', () async {
      final queue = await queueOf(
        words: [word(1), word(2)],
        progress: const [],
      ).call();

      expect(ids(queue.newWords), [1, 2]);
      expect(queue.due, isEmpty);
    });

    test('orders words without progress by id', () async {
      final queue = await queueOf(
        words: [word(3), word(1), word(2)],
        progress: const [],
      ).call();

      expect(ids(queue.newWords), [1, 2, 3]);
    });

    test('puts already introduced words before fresh ones', () async {
      final queue = await queueOf(
        words: [word(1), word(2)],
        progress: [newProgress(2, const Duration(days: 1))],
      ).call();

      expect(ids(queue.newWords), [2, 1]);
    });

    test('daily limits apply to words without progress', () async {
      final queue = await queueOf(
        words: [word(1), word(2), word(3)],
        progress: const [],
        settings: UserSettings.defaults().copyWith(dailyNewLimit: 2),
      ).call();

      expect(ids(queue.newWords), [1, 2]);
    });

    test('due word with progress appears in due', () async {
      final queue = await queueOf(
        words: [word(1)],
        progress: [dueProgress(1, const Duration(hours: -1))],
      ).call();

      expect(ids(queue.due), [1]);
      expect(queue.newWords, isEmpty);
    });

    test('newWords filtered by preferredLevel', () async {
      final queue = await queueOf(
        words: [
          word(1),
          word(2),
          word(3),
          word(4, level: CefrLevel.b2),
          word(5, level: CefrLevel.b2),
        ],
        progress: const [],
        settings: UserSettings.defaults().copyWith(
          preferredLevel: CefrLevel.a1,
          dailyNewLimit: 50,
        ),
      ).call();

      expect(ids(queue.newWords), [1, 2, 3]);
    });

    test('newWords include only the preferred level', () async {
      final queue = await queueOf(
        words: [
          word(1, level: CefrLevel.a0),
          word(2),
          word(3, level: CefrLevel.a2),
          word(4, level: CefrLevel.b1),
        ],
        progress: const [],
        settings: UserSettings.defaults().copyWith(
          preferredLevel: CefrLevel.a2,
          dailyNewLimit: 50,
        ),
      ).call();

      // Строгая фильтрация (Phase 27a): уровни ниже выбранного тоже отсекаются.
      expect(ids(queue.newWords), [3]);
    });

    test('dueWords filtered by level', () async {
      final queue = await queueOf(
        words: [word(1, level: CefrLevel.c1)],
        progress: [dueProgress(1, const Duration(hours: -1))],
        // Уровень пользователя A1: слово другого уровня не повторяем.
        settings: UserSettings.defaults().copyWith(
          preferredLevel: CefrLevel.a1,
        ),
      ).call();

      expect(queue.due, isEmpty);
      expect(queue.newWords, isEmpty);
    });

    test('newWord status filters out from due even when overdue', () async {
      final overdue = WordProgress(
        wordId: const WordId(1),
        cardState: CardState.initial(now.subtract(const Duration(hours: 2))),
        status: WordStatus.newWord,
        firstSeenAt: now.subtract(const Duration(days: 1)),
      );
      final queue = await queueOf(words: [word(1)], progress: [overdue]).call();

      expect(queue.due, isEmpty);
      expect(ids(queue.newWords), [1]);
    });

    test('returns only preferredLevel words in newWords', () async {
      final queue = await queueOf(
        words: [
          word(1, level: CefrLevel.a2),
          word(2, level: CefrLevel.b1),
          word(3, level: CefrLevel.a2),
        ],
        progress: const [],
        settings: UserSettings.defaults().copyWith(
          preferredLevel: CefrLevel.a2,
        ),
      ).call();

      expect(ids(queue.newWords), [1, 3]);
    });

    test('returns only preferredLevel words in due', () async {
      final queue = await queueOf(
        words: [
          word(1, level: CefrLevel.b1),
          word(2, level: CefrLevel.a2),
        ],
        progress: [
          dueProgress(1, const Duration(hours: -2)),
          dueProgress(2, const Duration(hours: -1)),
        ],
        settings: UserSettings.defaults().copyWith(
          preferredLevel: CefrLevel.b1,
        ),
      ).call();

      expect(ids(queue.due), [1]);
    });

    test('returns empty queue when no words at preferredLevel', () async {
      final queue = await queueOf(
        words: [word(1)],
        progress: [dueProgress(1, const Duration(hours: -1))],
        settings: UserSettings.defaults().copyWith(
          preferredLevel: CefrLevel.c2,
        ),
      ).call();

      expect(queue.due, isEmpty);
      expect(queue.newWords, isEmpty);
    });
  });
}
