import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_typing_session.dart';
import 'package:english_edu/domain/usecases/submit_typing_answer.dart';
import 'package:english_edu/domain/value_objects/typing_session.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

import 'fakes/fake_word_repository.dart';

List<Word> words(int count) => [
  for (var id = 1; id <= count; id++)
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id'),
];

void main() {
  group('GenerateTypingSession', () {
    test('should_take_requested_number_of_words', () async {
      final session = await GenerateTypingSession(
        words: FakeWordRepository(words(20)),
        random: Random(5),
      )();

      expect(session.length, 10);
      expect(session.index, 0);
      expect(session.correct, 0);
    });

    test('should_fall_back_to_available_words', () async {
      final session = await GenerateTypingSession(
        words: FakeWordRepository(words(3)),
        random: Random(5),
      )();

      expect(session.length, 3);
    });
  });

  group('SubmitTypingAnswer', () {
    const submit = SubmitTypingAnswer();

    TypingSession session() =>
        TypingSession(words: [words(1).single, words(2)[1]]);

    test('should_advance_on_correct_answer', () {
      final next = submit(session(), 'term1');

      expect(next.index, 1);
      expect(next.correct, 1);
    });

    test('should_ignore_case_and_spaces', () {
      final next = submit(session(), '  TERM1  ');

      expect(next.correct, 1);
    });

    test('should_not_count_wrong_answer', () {
      final next = submit(session(), 'wrong');

      expect(next.index, 1);
      expect(next.correct, 0);
    });
  });
}
