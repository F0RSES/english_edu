import 'package:english_edu/domain/value_objects/scramble_puzzle.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

ScramblePuzzle puzzle({
  WordId word = const WordId(1),
  String translation = 'яблоко',
  List<String> scrambled = const ['p', 'l', 'a', 'e'],
  String solution = 'apple',
}) => ScramblePuzzle(
  word: word,
  translation: translation,
  scrambled: scrambled,
  solution: solution,
);

void main() {
  group('ScramblePuzzle', () {
    test('equality and hashCode cover every field', () {
      final left = puzzle();
      final right = puzzle();

      expect(left, right);
      expect(left.hashCode, right.hashCode);
    });

    test('differs when the word id differs', () {
      expect(puzzle(), isNot(puzzle(word: const WordId(2))));
    });

    test('differs when the translation differs', () {
      expect(puzzle(), isNot(puzzle(translation: 'груша')));
    });

    test('differs when the letter order differs', () {
      // Порядок букв — часть задания, а не деталь реализации.
      expect(puzzle(), isNot(puzzle(scrambled: const ['l', 'p', 'a', 'e'])));
    });

    test('differs when the solution differs', () {
      expect(puzzle(), isNot(puzzle(solution: 'apples')));
    });

    test('keeps scrambled unmodifiable', () {
      final value = puzzle();

      expect(() => value.scrambled.add('x'), throwsUnsupportedError);
    });
  });
}
