import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/get_smart_review_queue.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word(int id) =>
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id');

WordProgress progress(
  int id, {
  int lapses = 0,
  int easePermille = 2500,
  int daysAgo = 0,
  WordStatus status = WordStatus.learning,
}) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: easePermille,
    intervalDays: 1,
    repetitions: 1,
    lapses: lapses,
    dueAt: now,
  ),
  status: status,
  firstSeenAt: now.subtract(Duration(days: daysAgo)),
  lastReviewedAt: now.subtract(Duration(days: daysAgo)),
);

GetSmartReviewQueue useCase({
  List<Word> words = const [],
  List<WordProgress> progressItems = const [],
  int maxItems = 20,
}) => GetSmartReviewQueue(
  words: FakeWordRepository(words),
  progress: FakeProgressRepository(progressItems),
  clock: () => now,
  maxItems: maxItems,
);

void main() {
  test('should_return_empty_when_there_is_no_progress', () async {
    expect(await useCase(words: [word(1)])(), isEmpty);
  });

  test('should_exclude_mastered_words', () async {
    final queue = await useCase(
      words: [word(1)],
      progressItems: [progress(1, lapses: 5, status: WordStatus.mastered)],
    )();

    expect(queue, isEmpty);
  });

  test('should_include_word_with_lapses', () async {
    final queue = await useCase(
      words: [word(1)],
      progressItems: [progress(1, lapses: 2)],
    )();

    expect(queue, hasLength(1));
    expect(queue.single.priorityScore, closeTo(20, 1e-9));
  });

  test('should_include_word_not_seen_for_more_than_a_week', () async {
    final queue = await useCase(
      words: [word(1)],
      progressItems: [progress(1, daysAgo: 10)],
    )();

    expect(queue, hasLength(1));
    expect(queue.single.reason, 'Не видел 10 дней');
    expect(queue.single.priorityScore, closeTo(10, 1e-9));
  });

  test('should_sort_by_priority_score_desc', () async {
    final queue = await useCase(
      words: [word(1), word(2)],
      progressItems: [progress(1, lapses: 1), progress(2, lapses: 3)],
    )();

    expect(queue.map((item) => item.word.id.value), [2, 1]);
  });

  test('should_rank_lapses_above_staleness', () async {
    // Один провал (10) весит больше девяти дней давности (9).
    final queue = await useCase(
      words: [word(1), word(2)],
      progressItems: [progress(1, daysAgo: 9), progress(2, lapses: 1)],
    )();

    expect(queue.first.word.id.value, 2);
  });

  test('should_add_score_for_low_ease', () async {
    final queue = await useCase(
      words: [word(1)],
      progressItems: [progress(1, easePermille: 1500)],
    )();

    expect(queue.single.priorityScore, closeTo(20, 1e-9));
    expect(queue.single.reason, 'Низкий ease');
  });

  test('should_respect_max_items', () async {
    final queue = await useCase(
      words: [word(1), word(2), word(3)],
      progressItems: [
        progress(1, lapses: 1),
        progress(2, lapses: 2),
        progress(3, lapses: 3),
      ],
      maxItems: 2,
    )();

    expect(queue, hasLength(2));
    expect(queue.map((item) => item.word.id.value), [3, 2]);
  });

  test('should_name_the_reason_by_lapses_count', () async {
    final queue = await useCase(
      words: [word(1)],
      progressItems: [progress(1, lapses: 5)],
    )();

    expect(queue.single.reason, 'Трудное (5 провалов)');
  });

  test('should_skip_progress_without_a_word', () async {
    final queue = await useCase(
      progressItems: [progress(1, lapses: 2)],
    )();

    expect(queue, isEmpty);
  });
}
