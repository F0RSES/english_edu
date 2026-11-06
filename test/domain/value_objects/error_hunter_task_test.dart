import 'package:english_edu/domain/value_objects/error_hunter_task.dart';
import 'package:test/test.dart';

Map<String, Object?> validJson() => {
  'sentence': 'I has a book',
  'wrongWord': 'has',
  'correctWord': 'have',
  'options': ['have', 'has', 'had'],
};

void main() {
  test('parses a valid task', () {
    final task = ErrorHunterTask.fromJson(validJson());

    expect(task.sentence, 'I has a book');
    expect(task.wrongWord, 'has');
    expect(task.correctWord, 'have');
    expect(task.options, ['have', 'has', 'had']);
  });

  test('derives the answer when the proxy omits correctWord', () {
    // Реальный ответ прокси на 2026-11-06 — без поля correctWord.
    final task = ErrorHunterTask.fromJson(const {
      'sentence': 'I have readed this book twice.',
      'wrongWord': 'readed',
      'options': ['readed', 'read', 'reading'],
    });

    expect(task.correctWord, 'read');
    expect(task.options, ['readed', 'read', 'reading']);
  });

  test('prefers the explicit correctWord from the payload', () {
    final task = ErrorHunterTask.fromJson(const {
      'sentence': 'I has a book',
      'wrongWord': 'has',
      'correctWord': 'have',
      'options': ['have', 'had'],
    });

    expect(task.correctWord, 'have');
  });

  test('rejects a missing sentence', () {
    final json = validJson()..remove('sentence');

    expect(() => ErrorHunterTask.fromJson(json), throwsFormatException);
  });

  test('rejects a non-string option', () {
    final json = validJson()..['options'] = ['have', 42];

    expect(() => ErrorHunterTask.fromJson(json), throwsFormatException);
  });

  test('rejects options without the correct word', () {
    final json = validJson()..['options'] = ['has', 'had'];

    expect(() => ErrorHunterTask.fromJson(json), throwsFormatException);
  });

  test('rejects an empty option list', () {
    final json = validJson()..['options'] = <String>[];

    expect(() => ErrorHunterTask.fromJson(json), throwsFormatException);
  });

  test('is equal and hashes equally for the same content', () {
    final first = ErrorHunterTask.fromJson(validJson());
    final second = ErrorHunterTask.fromJson(validJson());

    expect(first, equals(second));
    expect(first.hashCode, second.hashCode);
  });

  test('exposes options as an unmodifiable list', () {
    final task = ErrorHunterTask.fromJson(validJson());

    expect(() => task.options.add('extra'), throwsUnsupportedError);
  });
}
