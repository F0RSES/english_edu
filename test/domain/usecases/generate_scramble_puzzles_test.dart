import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_scramble_puzzles.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

import 'fakes/fake_word_repository.dart';

Word word(int id, String term) =>
    Word(id: WordId(id), term: term, translation: 'перевод$term');

GenerateScramblePuzzles generatorOf(List<Word> words, {int seed = 7}) =>
    GenerateScramblePuzzles(
      words: FakeWordRepository(words),
      random: Random(seed),
    );

void main() {
  group('GenerateScramblePuzzles', () {
    test('returns requested count', () async {
      final puzzles = await generatorOf([
        word(1, 'apple'),
        word(2, 'book'),
        word(3, 'cat'),
      ]).call(count: 2);

      expect(puzzles, hasLength(2));
    });

    test('returns every word when the dictionary is smaller than count', () {
      expect(
        generatorOf([word(1, 'apple'), word(2, 'book')]).call(),
        completion(hasLength(2)),
      );
    });

    test('scrambled != solution (guarantee)', () async {
      // Слова с разными буквами: перестановка возможна.
      final puzzles = await generatorOf([
        word(1, 'apple'),
        word(2, 'book'),
        word(3, 'garden'),
        word(4, 'listen'),
      ]).call(count: 4);

      for (final puzzle in puzzles) {
        expect(puzzle.scrambled.join(), isNot(puzzle.solution));
      }
    });

    test('returns empty if no words', () async {
      expect(await generatorOf(const []).call(), isEmpty);
    });

    test('uses provided Random (deterministic)', () async {
      final words = [word(1, 'apple'), word(2, 'book'), word(3, 'cat')];

      final first = await generatorOf(words, seed: 42).call(count: 3);
      final second = await generatorOf(words, seed: 42).call(count: 3);

      expect(
        [for (final puzzle in first) puzzle.solution],
        [for (final puzzle in second) puzzle.solution],
      );
      expect(
        [for (final puzzle in first) puzzle.scrambled.join()],
        [for (final puzzle in second) puzzle.scrambled.join()],
      );
    });

    test('scrambled letters match solution letters (same multiset)', () async {
      final puzzles = await generatorOf([word(1, 'banana'), word(2, 'letter')])
          .call(count: 2);

      for (final puzzle in puzzles) {
        final expected = puzzle.solution.split('')..sort();
        final actual = [...puzzle.scrambled]..sort();
        expect(actual, expected);
      }
    });

    test('skips single-letter words that cannot be scrambled', () async {
      final puzzles = await generatorOf([word(1, 'a'), word(2, 'book')]).call();

      expect([for (final puzzle in puzzles) puzzle.solution], ['book']);
    });

    test('lowercases the solution and the translation is kept as is', () async {
      final puzzle = (await generatorOf([word(1, 'Apple')]).call()).single;

      expect(puzzle.solution, 'apple');
      expect(puzzle.translation, 'переводApple');
    });

    test('count <= 0 yields nothing', () async {
      expect(await generatorOf([word(1, 'book')]).call(count: 0), isEmpty);
    });
  });
}
