import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/extract_unknown_words.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

import 'fakes/fake_word_repository.dart';

Word word(int id, String term) =>
    Word(id: WordId(id), term: term, translation: 'перевод');

void main() {
  test('extracts words not in repository', () async {
    final useCase = ExtractUnknownWords(
      words: FakeWordRepository([word(1, 'cat')]),
    );

    final unknown = await useCase('The cat sleeps on the sofa');

    expect(unknown, containsAll(<String>['sleeps', 'sofa']));
    expect(unknown, isNot(contains('cat')));
  });

  test('ignores known words', () async {
    final useCase = ExtractUnknownWords(
      words: FakeWordRepository([word(1, 'cat'), word(2, 'sleeps')]),
    );

    final unknown = await useCase('cat sleeps');

    expect(unknown, isEmpty);
  });

  test('cleans punctuation and case', () async {
    final useCase = ExtractUnknownWords(words: FakeWordRepository());

    final unknown = await useCase('Hello, WORLD! Hello...');

    expect(unknown, <String>['hello', 'world']);
  });

  test('ignores words <= 2 chars', () async {
    final useCase = ExtractUnknownWords(words: FakeWordRepository());

    final unknown = await useCase('I am at the big cat');

    expect(unknown, <String>['the', 'big', 'cat']);
  });

  test('empty text → empty list', () async {
    final useCase = ExtractUnknownWords(words: FakeWordRepository());

    expect(await useCase(''), isEmpty);
  });
}
