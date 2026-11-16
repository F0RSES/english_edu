import 'dart:math';

import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_listening_sentence.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

import 'fakes/fake_sentence_generator.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_word_repository.dart';

Word word(
  int id,
  String term, {
  String? example = 'I eat an apple every day',
  CefrLevel level = CefrLevel.a1,
}) => Word(
  id: WordId(id),
  term: term,
  translation: 'перевод$term',
  exampleSentence: example,
  level: level,
);

GenerateListeningSentence generatorOf(
  List<Word> words, {
  FakeSentenceGenerator? generator,
  UserSettings? settings,
  int seed = 7,
}) => GenerateListeningSentence(
  words: FakeWordRepository(words),
  generator: generator ?? FakeSentenceGenerator(),
  settings: FakeSettingsRepository(settings),
  random: Random(seed),
);

void main() {
  group('GenerateListeningSentence', () {
    test('uses exampleSentence offline without shuffling', () async {
      final generator = FakeSentenceGenerator();

      final puzzle = await generatorOf([
        word(1, 'apple'),
      ], generator: generator).call();

      expect(puzzle.sentence, 'I eat an apple every day');
      expect(puzzle.translation, 'переводapple');
      expect(puzzle.shuffledWords, isEmpty);
      expect(generator.calls, 0);
    });

    test('falls back to AI when exampleSentence is null', () async {
      final generator = FakeSentenceGenerator();

      final puzzle = await generatorOf([
        word(1, 'apple', example: null),
      ], generator: generator).call();

      expect(puzzle.sentence, generator.puzzle.sentence);
      expect(puzzle.translation, generator.puzzle.translation);
      expect(puzzle.shuffledWords, isEmpty);
      expect(generator.calls, 1);
      expect(generator.words, ['apple']);
      expect(generator.levels, ['A1']);
    });

    test('falls back to AI when exampleSentence is blank', () async {
      final generator = FakeSentenceGenerator();

      await generatorOf([
        word(1, 'apple', example: '   '),
      ], generator: generator).call();

      expect(generator.calls, 1);
    });

    test('uses only preferred level words', () async {
      final puzzle = await generatorOf([
        word(1, 'apple'),
        word(
          2,
          'facility',
          example: 'The facility is new',
          level: CefrLevel.b2,
        ),
      ], settings: const UserSettings(preferredLevel: CefrLevel.b2)).call();

      expect(puzzle.sentence, 'The facility is new');
    });

    test('uses provided Random (deterministic)', () async {
      final words = [
        word(1, 'apple'),
        word(2, 'book', example: 'I read a book'),
      ];

      final first = await generatorOf(words, seed: 42).call();
      final second = await generatorOf(words, seed: 42).call();

      expect(first, second);
    });

    test('normalizes whitespace in the example', () async {
      final puzzle = await generatorOf([
        word(1, 'apple', example: 'I  eat   an apple.'),
      ]).call();

      expect(puzzle.sentence, 'I eat an apple.');
    });

    test('throws StateError when the dictionary is empty', () async {
      final generator = FakeSentenceGenerator();

      await expectLater(
        generatorOf(const [], generator: generator).call(),
        throwsStateError,
      );
      expect(generator.calls, 0);
    });
  });
}
