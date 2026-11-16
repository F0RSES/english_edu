import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_listening_sentence.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/listening_v2_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/tts/fake_tts_service.dart';
import '../../domain/usecases/fakes/fake_sentence_generator.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

const _sentence = 'I eat an apple every day';

Word apple() => const Word(
  id: WordId(1),
  term: 'apple',
  translation: 'яблоко',
  exampleSentence: _sentence,
);

Widget host({List<Word>? words, UserSettings? settings, FakeTtsService? tts}) {
  final repository = FakeWordRepository(words ?? [apple()]);
  final fakeSettings = FakeSettingsRepository(settings);
  return ProviderScope(
    overrides: [
      wordRepositoryProvider.overrideWithValue(repository),
      settingsRepositoryProvider.overrideWithValue(fakeSettings),
      ttsProvider.overrideWithValue(tts ?? FakeTtsService()),
      sentenceGeneratorProvider.overrideWithValue(FakeSentenceGenerator()),
      generateListeningSentenceProvider.overrideWithValue(
        GenerateListeningSentence(
          words: repository,
          generator: FakeSentenceGenerator(),
          settings: fakeSettings,
          random: Random(5),
        ),
      ),
    ],
    child: const MaterialApp(home: ListeningV2Screen()),
  );
}

void main() {
  testWidgets('renders speaker, instruction and input', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Прослушай и запиши предложение'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.byKey(const ValueKey('speak-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('show-translation')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('check-button')), findsOneWidget);
  });

  testWidgets('tapping the speaker reads the sentence via TTS', (tester) async {
    final tts = FakeTtsService();
    await tester.pumpWidget(host(tts: tts));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('speak-button')));
    await tester.pumpAndSettle();

    expect(tts.speakCount, 1);
    expect(tts.lastText, _sentence);
    expect(tts.lastVoice, 'en-US');
    expect(tts.lastSpeed, 0.5);
  });

  testWidgets('show translation reveals the hint', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('show-translation')));
    await tester.pump();

    expect(find.text('яблоко'), findsOneWidget);
    expect(find.byKey(const ValueKey('show-translation')), findsNothing);
  });

  testWidgets('correct input ignores case and punctuation', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('answer-field')),
      'i eat an apple every day.',
    );
    await tester.tap(find.byKey(const ValueKey('check-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('next-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('wrong-card')), findsNothing);
  });

  testWidgets('wrong input shows the correct sentence', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('answer-field')),
      'I eat a banana',
    );
    await tester.tap(find.byKey(const ValueKey('check-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('wrong-card')), findsOneWidget);
    expect(
      find.text('Неверно. Правильно: I eat an apple every day'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('next-button')), findsOneWidget);
  });

  testWidgets('session summary appears after five sentences', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    for (var round = 0; round < 5; round++) {
      await tester.enterText(
        find.byKey(const ValueKey('answer-field')),
        _sentence,
      );
      await tester.tap(find.byKey(const ValueKey('check-button')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('next-button')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Сессия завершена'), findsOneWidget);
    expect(find.text('Верно: 5 из 5'), findsOneWidget);

    await tester.tap(find.text('Ещё раз'));
    await tester.pumpAndSettle();

    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('TTS failure shows a snackbar and keeps the game', (
    tester,
  ) async {
    final tts = FakeTtsService()..speakThrows = true;
    await tester.pumpWidget(host(tts: tts));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('speak-button')));
    await tester.pumpAndSettle();

    expect(find.text('Озвучка недоступна'), findsOneWidget);
    expect(find.byKey(const ValueKey('check-button')), findsOneWidget);
  });

  testWidgets('shows error state with retry when dictionary is empty', (
    tester,
  ) async {
    await tester.pumpWidget(host(words: const []));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('switches to EN labels when lang=en', (tester) async {
    await tester.pumpWidget(
      host(settings: const UserSettings(language: AppLanguage.en)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sentence Dictation'), findsOneWidget);
    expect(find.text('Listen and write'), findsOneWidget);
    expect(find.text('Show translation'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Check'), findsOneWidget);
  });
}
