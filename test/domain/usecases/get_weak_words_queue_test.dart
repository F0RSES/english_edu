import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/get_weak_words_queue.dart';
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

/// Прогресс с заданными lapses и ease (ease — множитель, не permille).
WordProgress progress(
  int id, {
  int lapses = 0,
  double ease = 2.5,
  WordStatus status = WordStatus.learning,
}) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: (ease * 1000).round(),
    intervalDays: 3,
    repetitions: 2,
    lapses: lapses,
    dueAt: now.add(const Duration(days: 3)),
  ),
  status: status,
  firstSeenAt: now.subtract(const Duration(days: 10)),
);

GetWeakWordsQueue queueOf({
  required List<Word> words,
  required List<WordProgress> progress,
}) => GetWeakWordsQueue(
  words: FakeWordRepository(words),
  progress: FakeProgressRepository(progress),
  settings: FakeSettingsRepository(),
);

List<int> ids(List<Word> words) => [for (final item in words) item.id.value];

void main() {
  group('GetWeakWordsQueue', () {
    test('returns words with lapses > 0', () async {
      final queue = await queueOf(
        words: [word(1), word(2)],
        progress: [progress(1, lapses: 2), progress(2)],
      ).call();

      expect(ids(queue.due), [1]);
      expect(queue.newWords, isEmpty);
    });

    test('returns words with ease < 2.0', () async {
      final queue = await queueOf(
        words: [word(1), word(2)],
        progress: [progress(1, ease: 1.7), progress(2, ease: 2.1)],
      ).call();

      expect(ids(queue.due), [1]);
    });

    test('does not return healthy words (lapses=0, ease>=2.0)', () async {
      final queue = await queueOf(
        words: [word(1), word(2), word(3)],
        progress: [progress(1), progress(2, ease: 2), progress(3)],
      ).call();

      expect(queue.due, isEmpty);
      expect(queue.length, 0);
    });

    test('sorts by lapses desc, then ease asc', () async {
      final queue = await queueOf(
        words: [word(1), word(2), word(3), word(4)],
        progress: [
          progress(1, lapses: 1, ease: 1.9),
          progress(2, lapses: 3, ease: 2.4),
          progress(3, lapses: 1, ease: 1.5),
          progress(4, lapses: 3, ease: 1.6),
        ],
      ).call();

      // Сначала больше провалов (3, затем 1), внутри группы — меньше ease.
      expect(ids(queue.due), [4, 2, 3, 1]);
    });

    test('returns empty queue if no weak words', () async {
      final queue = await queueOf(words: [word(1)], progress: const []).call();

      expect(queue.due, isEmpty);
      expect(queue.newWords, isEmpty);
    });

    test('skips progress of a deleted word', () async {
      // Прогресс пережил слово: показывать нечего, но очередь не падает.
      final queue = await queueOf(
        words: const [],
        progress: [progress(1, lapses: 5)],
      ).call();

      expect(queue.due, isEmpty);
    });

    test('includes mastered words with lapses', () async {
      final queue = await queueOf(
        words: [word(1)],
        progress: [progress(1, lapses: 1, status: WordStatus.mastered)],
      ).call();

      // Статус не фильтр: провал возвращает слово в повторение.
      expect(ids(queue.due), [1]);
    });

    test('filters by preferred level', () async {
      final queue = await queueOf(
        words: [
          word(1),
          word(2, level: CefrLevel.b2),
        ],
        progress: [progress(1, lapses: 2), progress(2, lapses: 3)],
      ).call();

      expect(ids(queue.due), [1]);
    });
  });
}
