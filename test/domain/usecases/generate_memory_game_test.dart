import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_memory_game.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

import 'fakes/fake_word_repository.dart';

List<Word> words(int count) => [
  for (var id = 1; id <= count; id++)
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id'),
];

GenerateMemoryGame useCase(int wordCount, {int pairs = 8}) =>
    GenerateMemoryGame(
      words: FakeWordRepository(words(wordCount)),
      random: Random(7),
      pairsCount: pairs,
    );

void main() {
  test('should_generate_requested_pairs', () async {
    final game = await useCase(20)();

    expect(game.cards, hasLength(16));
    expect(game.pairsTotal, 8);
    expect(game.moves, 0);
    expect(game.isWon, isFalse);
  });

  test('should_give_each_pair_one_english_and_one_translation', () async {
    final game = await useCase(20)();

    for (var pairId = 0; pairId < 8; pairId++) {
      final pair = [
        for (final card in game.cards)
          if (card.pairId == pairId) card,
      ];
      expect(pair, hasLength(2));
      expect(pair.where((card) => card.isEnglish), hasLength(1));
      expect(pair.where((card) => !card.isEnglish), hasLength(1));
    }
  });

  test('should_shuffle_the_deck', () async {
    final game = await useCase(20)();

    // Неотсортированный порядок: пары не идут строго друг за другом.
    final pairedOrder = [
      for (final card in game.cards) card.pairId,
    ];
    expect(pairedOrder, isNot([for (var i = 0; i < 8; i++) ...[i, i]]));
  });

  test('should_fall_back_to_available_words', () async {
    final game = await useCase(3)().timeout(const Duration(seconds: 1));

    expect(game.pairsTotal, 3);
    expect(game.cards, hasLength(6));
  });

  test('should_return_empty_game_for_empty_dictionary', () async {
    final game = await GenerateMemoryGame(
      words: FakeWordRepository(),
      random: Random(1),
    )();

    expect(game.cards, isEmpty);
  });
}
