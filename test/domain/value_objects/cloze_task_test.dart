import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:test/test.dart';

Map<String, Object?> validJson() => {
  'sentence': 'I ___ apples every day.',
  'correctWord': 'eat',
  'options': ['eat', 'eats', 'ate', 'eating', 'eaten'],
};

void main() {
  group('ClozeTask.fromJson', () {
    test('parses sentence, correctWord and options', () {
      final task = ClozeTask.fromJson(validJson());

      expect(task.sentence, 'I ___ apples every day.');
      expect(task.correctWord, 'eat');
      expect(task.options, ['eat', 'eats', 'ate', 'eating', 'eaten']);
    });

    test('rejects a missing sentence', () {
      final json = validJson()..remove('sentence');

      expect(() => ClozeTask.fromJson(json), throwsFormatException);
    });

    test('rejects a blank correctWord', () {
      final json = validJson()..['correctWord'] = '   ';

      expect(() => ClozeTask.fromJson(json), throwsFormatException);
    });

    test('rejects missing options', () {
      final json = validJson()..remove('options');

      expect(() => ClozeTask.fromJson(json), throwsFormatException);
    });

    test('rejects options when not exactly five', () {
      final json = validJson()..['options'] = ['eat', 'eats', 'ate'];

      expect(() => ClozeTask.fromJson(json), throwsFormatException);
    });

    test('rejects options without correctWord', () {
      final json = validJson()
        ..['options'] = ['drink', 'drinks', 'drank', 'drinking', 'drunk'];

      expect(() => ClozeTask.fromJson(json), throwsFormatException);
    });

    test('accepts correctWord in options ignoring case', () {
      final json = validJson()..['correctWord'] = 'Eat';

      final task = ClozeTask.fromJson(json);

      expect(task.correctWord, 'Eat');
    });
  });

  test('equality is structural', () {
    final left = ClozeTask.fromJson(validJson());
    final right = ClozeTask.fromJson(validJson());
    final other = left.copyWith(correctWord: 'love');

    expect(left, right);
    expect(left.hashCode, right.hashCode);
    expect(left, isNot(other));
  });

  test('copyWith replaces fields and keeps the rest', () {
    final task = ClozeTask.fromJson(validJson());
    final copy = task.copyWith(
      sentence: 'She ___ tea.',
      options: ['drinks', 'drink', 'drank', 'drinking', 'drunk'],
    );

    expect(copy.sentence, 'She ___ tea.');
    expect(copy.correctWord, task.correctWord);
    expect(copy.options, ['drinks', 'drink', 'drank', 'drinking', 'drunk']);
  });

  test('exposes options as an unmodifiable list', () {
    final task = ClozeTask.fromJson(validJson());

    expect(() => task.options.add('extra'), throwsUnsupportedError);
  });
}
