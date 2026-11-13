import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

void main() {
  group('WordStatus', () {
    test('declares exactly three statuses in order', () {
      expect(WordStatus.values, [
        WordStatus.newWord,
        WordStatus.learning,
        WordStatus.mastered,
      ]);
    });

    test('is exhaustive in a switch expression', () {
      String describe(WordStatus status) => switch (status) {
            WordStatus.newWord => 'new',
            WordStatus.learning => 'learning',
            WordStatus.mastered => 'mastered',
          };

      expect(
        WordStatus.values.map(describe).toList(),
        ['new', 'learning', 'mastered'],
      );
    });

    test('keeps a stable name for serialisation', () {
      expect(WordStatus.newWord.name, 'newWord');
      expect(WordStatus.learning.name, 'learning');
      expect(WordStatus.mastered.name, 'mastered');
    });
  });
}
