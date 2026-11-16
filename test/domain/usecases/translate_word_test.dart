import 'package:english_edu/domain/usecases/translate_word.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:test/test.dart';

import 'fakes/fake_translation_generator.dart';
import 'fakes/fake_word_translation_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

const fresh = WordTranslation(
  text: 'яблоко',
  partOfSpeech: 'noun',
  transcription: '/ˈæp.əl/',
  example: 'I eat an apple.',
);

TranslateWord translatorOf({
  FakeWordTranslationRepository? translations,
  FakeTranslationGenerator? generator,
}) => TranslateWord(
  translations: translations ?? FakeWordTranslationRepository(),
  generator: generator ?? FakeTranslationGenerator(translation: fresh),
  clock: () => now,
);

void main() {
  test('returns cached translation without calling AI', () async {
    final generator = FakeTranslationGenerator();
    final translations = FakeWordTranslationRepository({
      'apple': const WordTranslation(text: 'из кэша'),
    });

    final result = await translatorOf(
      translations: translations,
      generator: generator,
    ).translate('apple');

    expect(result.text, 'из кэша');
    expect(generator.calls, 0);
  });

  test('second call hits the cache instead of the network', () async {
    final generator = FakeTranslationGenerator(translation: fresh);
    final translations = FakeWordTranslationRepository();
    final translator = translatorOf(
      translations: translations,
      generator: generator,
    );

    final first = await translator.translate('apple');
    final second = await translator.translate('apple');

    expect(first, fresh);
    expect(second, fresh);
    expect(generator.calls, 1);
    expect(translations.saved, hasLength(1));
  });

  test('fetches from AI and saves to cache when empty', () async {
    final generator = FakeTranslationGenerator(translation: fresh);
    final translations = FakeWordTranslationRepository();

    final result = await translatorOf(
      translations: translations,
      generator: generator,
    ).translate('apple');

    expect(result, fresh);
    expect(generator.calls, 1);
    expect(generator.words, ['apple']);
    expect(translations.saved.single.$1, 'apple');
    expect(translations.saved.single.$2, fresh);
    expect(translations.saved.single.$3, now);
  });

  test('does not cache an AI error', () async {
    final generator = FakeTranslationGenerator(error: Exception('proxy down'));
    final translations = FakeWordTranslationRepository();

    await expectLater(
      translatorOf(
        translations: translations,
        generator: generator,
      ).translate('apple'),
      throwsException,
    );

    expect(translations.saved, isEmpty);
    expect(await translations.findByTerm('apple'), isNull);
  });
}
