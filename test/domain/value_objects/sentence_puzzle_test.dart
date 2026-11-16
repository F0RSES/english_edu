import 'package:english_edu/domain/value_objects/sentence_puzzle.dart';
import 'package:test/test.dart';

SentencePuzzle puzzle({
  String sentence = 'I eat an apple',
  List<String> shuffledWords = const ['apple', 'I', 'an', 'eat'],
  String translation = 'Я ем яблоко',
}) => SentencePuzzle(
  sentence: sentence,
  shuffledWords: shuffledWords,
  translation: translation,
);

void main() {
  group('SentencePuzzle', () {
    test('equality and hashCode cover every field', () {
      final left = puzzle();
      final right = puzzle();

      expect(left, right);
      expect(left.hashCode, right.hashCode);
    });

    test('differs when the sentence differs', () {
      expect(puzzle(), isNot(puzzle(sentence: 'I eat a pear')));
    });

    test('differs when the translation differs', () {
      expect(puzzle(), isNot(puzzle(translation: 'Я ем грушу')));
    });

    test('differs when the word order differs', () {
      // Порядок слов — часть задания, а не деталь реализации.
      expect(
        puzzle(),
        isNot(puzzle(shuffledWords: const ['I', 'apple', 'an', 'eat'])),
      );
    });

    test('keeps shuffledWords unmodifiable', () {
      final value = puzzle();

      expect(() => value.shuffledWords.add('x'), throwsUnsupportedError);
    });

    test('copyWith replaces fields and keeps the rest', () {
      final value = puzzle();
      final copy = value.copyWith(translation: 'новый перевод');

      expect(copy.translation, 'новый перевод');
      expect(copy.sentence, value.sentence);
      expect(copy.shuffledWords, value.shuffledWords);
      expect(copy, isNot(value));
    });

    test('toString contains the sentence and translation', () {
      expect(puzzle().toString(), contains('I eat an apple'));
      expect(puzzle().toString(), contains('Я ем яблоко'));
    });
  });
}
