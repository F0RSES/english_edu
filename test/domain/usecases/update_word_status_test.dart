import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/app_meta_repository.dart';
import 'package:english_edu/domain/usecases/update_word_status.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

import 'fakes/fake_app_meta_repository.dart';
import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_word_repository.dart';

final now = DateTime.utc(2026, 11, 18, 12);

void main() {
  late FakeWordRepository words;
  late FakeProgressRepository progress;
  late FakeAppMetaRepository meta;
  late UpdateWordStatus useCase;

  setUp(() {
    words = FakeWordRepository([
      const Word(id: WordId(29), term: 'apple', translation: 'яблоко'),
      const Word(id: WordId(9000), term: 'myword', translation: 'моё слово'),
    ]);
    progress = FakeProgressRepository();
    meta = FakeAppMetaRepository({AppMetaRepository.seedMaxIdKey: '7415'});
    useCase = UpdateWordStatus(
      words: words,
      progress: progress,
      meta: meta,
      clock: () => now,
    );
  });

  test('adds a learning progress row for a new word', () async {
    await useCase(const WordId(29), WordStatus.learning);

    final stored = await progress.getByWordId(const WordId(29));
    expect(stored!.status, WordStatus.learning);
    expect(stored.firstSeenAt, now);
    expect(stored.cardState, CardState.initial(now));
  });

  test('marks a learning word mastered keeping its card state', () async {
    final card = CardState.initial(now)
        .copyWith(repetitions: 4, intervalDays: 9);
    await progress.upsert(
      WordProgress(
        wordId: const WordId(29),
        cardState: card,
        status: WordStatus.learning,
        firstSeenAt: now,
      ),
    );

    await useCase(const WordId(29), WordStatus.mastered);

    final stored = await progress.getByWordId(const WordId(29));
    expect(stored!.status, WordStatus.mastered);
    expect(stored.cardState, card);
  });

  test('reset removes progress of a seed word but keeps the word', () async {
    await progress.upsert(
      WordProgress(
        wordId: const WordId(29),
        cardState: CardState.initial(now),
        status: WordStatus.mastered,
        firstSeenAt: now,
      ),
    );

    await useCase(const WordId(29), WordStatus.newWord);

    expect(await progress.getByWordId(const WordId(29)), isNull);
    expect(await words.getById(const WordId(29)), isNotNull);
  });

  test('reset deletes a custom word entirely', () async {
    await useCase(const WordId(9000), WordStatus.newWord);

    expect(await words.getById(const WordId(9000)), isNull);
  });

  test('missing seed_max_id falls back to reset, never deletion', () async {
    final bareMeta = FakeAppMetaRepository();
    final conservative = UpdateWordStatus(
      words: words,
      progress: progress,
      meta: bareMeta,
      clock: () => now,
    );

    await conservative(const WordId(9000), WordStatus.newWord);

    expect(await words.getById(const WordId(9000)), isNotNull);
  });
}
