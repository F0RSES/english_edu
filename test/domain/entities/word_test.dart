import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

void main() {
  const base = Word(id: WordId(1), term: 'book', translation: 'книга');

  group('Word', () {
    test('keeps the given values', () {
      expect(base.id, const WordId(1));
      expect(base.term, 'book');
      expect(base.translation, 'книга');
      expect(base.transcription, isNull);
      expect(base.partOfSpeech, isNull);
      expect(base.exampleSentence, isNull);
    });

    test('rejects an empty term', () {
      expect(
        () => Word(id: const WordId(1), term: '', translation: 'книга'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an empty translation', () {
      expect(
        () => Word(id: const WordId(1), term: 'book', translation: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('is equal and has the same hash for equal fields', () {
      const other = Word(id: WordId(1), term: 'book', translation: 'книга');
      expect(base, equals(other));
      expect(base.hashCode, other.hashCode);
    });

    test('differs when a field differs', () {
      expect(base, isNot(equals(base.copyWith(term: 'booklet'))));
    });

    test('copyWith replaces text and keeps nullable fields', () {
      const withExtras = Word(
        id: WordId(1),
        term: 'book',
        translation: 'книга',
        transcription: 'bʊk',
        partOfSpeech: 'noun',
      );
      final updated = withExtras.copyWith(translation: 'том');
      expect(updated.translation, 'том');
      expect(updated.transcription, 'bʊk');
      expect(updated.partOfSpeech, 'noun');
    });

    test('copyWith clears a nullable field with explicit null', () {
      const withExtras = Word(
        id: WordId(1),
        term: 'book',
        translation: 'книга',
        transcription: 'bʊk',
      );
      expect(withExtras.copyWith(transcription: null).transcription, isNull);
    });

    test('copyWith without arguments returns an equal word', () {
      expect(base.copyWith(), equals(base));
    });

    test('renders id, term and translation', () {
      expect(base.toString(), 'Word(1, "book" → "книга")');
    });
  });
}
