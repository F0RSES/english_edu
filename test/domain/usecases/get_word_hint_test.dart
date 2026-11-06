import 'package:english_edu/domain/usecases/get_word_hint.dart';
import 'package:english_edu/domain/value_objects/word_hint.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

import 'fakes/fake_hint_generator.dart';
import 'fakes/fake_word_hint_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

WordHint cachedHint({String term = 'hello', String text = 'из кэша'}) =>
    WordHint(
      wordId: const WordId(1),
      term: term,
      hintText: text,
      createdAtUtc: now,
    );

GetWordHint hintOf({
  FakeWordHintRepository? hints,
  FakeHintGenerator? generator,
}) => GetWordHint(
  hints: hints ?? FakeWordHintRepository(),
  generator: generator ?? FakeHintGenerator(),
  clock: () => now,
);

void main() {
  test('returns cached hint if term matches', () async {
    final generator = FakeHintGenerator();
    final hints = FakeWordHintRepository([cachedHint()]);

    final text = await hintOf(
      hints: hints,
      generator: generator,
    ).call(const WordId(1), 'hello');

    expect(text, 'из кэша');
    expect(generator.calls, 0);
  });

  test('fetches from AI if no cache', () async {
    final generator = FakeHintGenerator(hint: 'свежая подсказка');
    final hints = FakeWordHintRepository();

    final text = await hintOf(
      hints: hints,
      generator: generator,
    ).call(const WordId(1), 'hello');

    expect(text, 'свежая подсказка');
    expect(generator.calls, 1);
    expect(generator.words, ['hello']);
    expect(hints.saved.single.hintText, 'свежая подсказка');
    expect(hints.saved.single.term, 'hello');
    expect(hints.saved.single.createdAtUtc, now);
  });

  test('fetches from AI if the term changed', () async {
    final generator = FakeHintGenerator(hint: 'новая подсказка');
    final hints = FakeWordHintRepository([cachedHint(term: 'helo')]);

    final text = await hintOf(
      hints: hints,
      generator: generator,
    ).call(const WordId(1), 'hello');

    expect(text, 'новая подсказка');
    expect(generator.calls, 1);
    // Кэш перезаписан новым написанием — старая ассоциация больше не вернётся.
    expect((await hints.getByWordId(const WordId(1)))!.term, 'hello');
  });

  test('does not cache an AI error', () async {
    final generator = FakeHintGenerator(throwOnGenerate: true);
    final hints = FakeWordHintRepository();

    await expectLater(
      hintOf(hints: hints, generator: generator).call(const WordId(1), 'hello'),
      throwsStateError,
    );

    expect(hints.saved, isEmpty);
    expect(await hints.getByWordId(const WordId(1)), isNull);
  });
}
