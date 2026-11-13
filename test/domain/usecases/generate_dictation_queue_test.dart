import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_dictation_queue.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_word_repository.dart';

Word word(int id, String term) =>
    Word(id: WordId(id), term: term, translation: 'перевод$term');

GenerateDictationQueue queueOf(List<Word> words, {int seed = 11}) =>
    GenerateDictationQueue(
      words: FakeWordRepository(words),
      settings: FakeSettingsRepository(),
      random: Random(seed),
    );

void main() {
  group('GenerateDictationQueue', () {
    test('returns requested count', () async {
      final queue = await queueOf([
        word(1, 'apple'),
        word(2, 'book'),
        word(3, 'cat'),
      ]).call(count: 2);

      expect(queue, hasLength(2));
    });

    test('returns every word when the dictionary is smaller than count', () {
      expect(
        queueOf([word(1, 'apple'), word(2, 'book')]).call(),
        completion(hasLength(2)),
      );
    });

    test('returns empty for empty DB', () async {
      expect(await queueOf(const []).call(), isEmpty);
    });

    test('uses provided Random (deterministic)', () async {
      final words = [word(1, 'apple'), word(2, 'book'), word(3, 'cat')];

      final first = await queueOf(words, seed: 5).call();
      final second = await queueOf(words, seed: 5).call();

      expect(
        [for (final item in first) item.term],
        [for (final item in second) item.term],
      );
    });

    test('count <= 0 yields nothing', () async {
      expect(await queueOf([word(1, 'apple')]).call(count: 0), isEmpty);
    });

    test('uses only preferred level words', () async {
      final queue = await GenerateDictationQueue(
        words: FakeWordRepository([
          word(1, 'apple'),
          const Word(
            id: WordId(2),
            term: 'book',
            translation: 'переводbook',
            level: CefrLevel.b2,
          ),
        ]),
        settings: FakeSettingsRepository(),
        random: Random(11),
      ).call();

      expect([for (final item in queue) item.term], ['apple']);
    });
  });
}
