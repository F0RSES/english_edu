import 'package:english_edu/domain/value_objects/word_category.dart';
import 'package:test/test.dart';

void main() {
  group('values', () {
    test('holds all plus 22 thematic categories', () {
      expect(WordCategory.values, hasLength(23));
      expect(WordCategory.values.first, WordCategory.all);
    });
  });

  group('fromString', () {
    test('parses every key', () {
      for (final category in WordCategory.values) {
        expect(WordCategory.fromString(category.key), category);
      }
    });

    test('parses russian and english names ignoring case', () {
      expect(WordCategory.fromString('Еда'), WordCategory.food);
      expect(WordCategory.fromString('FOOD'), WordCategory.food);
      expect(WordCategory.fromString('  Животные  '), WordCategory.animals);
      expect(WordCategory.fromString('Путешествия'), WordCategory.travel);
    });

    test('parses legacy user category aliases', () {
      expect(WordCategory.fromString('IT'), WordCategory.computers);
      expect(WordCategory.fromString('Быт'), WordCategory.home);
    });

    test('throws on an unknown value', () {
      expect(() => WordCategory.fromString('Бизнес'), throwsArgumentError);
      expect(() => WordCategory.fromString(''), throwsArgumentError);
    });
  });

  group('matches', () {
    test('all matches any word', () {
      expect(WordCategory.all.matches(), isTrue);
      expect(
        WordCategory.all.matches(category: 'Бизнес', partOfSpeech: 'noun'),
        isTrue,
      );
    });

    test('verbs matches part of speech when category is null', () {
      expect(WordCategory.verbs.matches(partOfSpeech: 'verb'), isTrue);
      expect(WordCategory.verbs.matches(partOfSpeech: 'noun'), isFalse);
      expect(WordCategory.verbs.matches(), isFalse);
    });

    test('adverbs and adjectives match their part of speech', () {
      expect(WordCategory.adverbs.matches(partOfSpeech: 'adverb'), isTrue);
      expect(
        WordCategory.adjectives.matches(partOfSpeech: 'adjective'),
        isTrue,
      );
      expect(WordCategory.adverbs.matches(partOfSpeech: 'adjective'), isFalse);
    });

    test('pos categories also match the category string', () {
      expect(WordCategory.verbs.matches(category: 'Глаголы'), isTrue);
      expect(WordCategory.verbs.matches(category: 'verbs'), isTrue);
    });

    test(
      'thematic categories match key and ru/en names case-insensitively',
      () {
        expect(WordCategory.food.matches(category: 'еда'), isTrue);
        expect(WordCategory.food.matches(category: 'Food'), isTrue);
        expect(WordCategory.food.matches(category: 'food'), isTrue);
        expect(WordCategory.food.matches(category: '  ЕДА  '), isTrue);
      },
    );

    test('thematic categories ignore part of speech', () {
      expect(WordCategory.food.matches(partOfSpeech: 'noun'), isFalse);
    });

    test('legacy aliases keep old user categories findable', () {
      expect(WordCategory.computers.matches(category: 'IT'), isTrue);
      expect(WordCategory.home.matches(category: 'Быт'), isTrue);
      expect(WordCategory.travel.matches(category: 'Путешествия'), isTrue);
    });

    test('unknown category matches nothing but all', () {
      expect(WordCategory.food.matches(category: 'Бизнес'), isFalse);
      expect(WordCategory.animals.matches(), isFalse);
    });
  });
}
