import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_sentence_puzzle.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/sentence_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Widget host({List<Word>? words, UserSettings? settings}) {
  final repository = FakeWordRepository(words ?? [apple()]);
  final fakeSettings = FakeSettingsRepository(settings);
  return ProviderScope(
    overrides: [
      wordRepositoryProvider.overrideWithValue(repository),
      settingsRepositoryProvider.overrideWithValue(fakeSettings),
      sentenceGeneratorProvider.overrideWithValue(FakeSentenceGenerator()),
      generateSentencePuzzleProvider.overrideWithValue(
        GenerateSentencePuzzle(
          words: repository,
          generator: FakeSentenceGenerator(),
          settings: fakeSettings,
          random: Random(5),
        ),
      ),
    ],
    child: const MaterialApp(home: SentenceBuilderScreen()),
  );
}

/// Тапает слова облака в порядке [tokens] (повторов в фикстуре нет).
Future<void> tapWords(WidgetTester tester, List<String> tokens) async {
  for (final token in tokens) {
    await tester.tap(find.widgetWithText(FilledButton, token));
    await tester.pump();
  }
}

/// Собирает предложение в правильном порядке и проверяет его.
Future<void> solveCurrent(WidgetTester tester) async {
  await tapWords(tester, _sentence.split(' '));
  await tester.tap(find.byKey(const ValueKey('check-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders translation, instruction and word cloud', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('яблоко'), findsOneWidget);
    expect(find.text('Собери предложение из слов'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    for (var index = 0; index < 6; index++) {
      expect(find.byKey(ValueKey('word-$index')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('check-button')), findsOneWidget);
  });

  testWidgets('tapping a cloud word moves it to the answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('word-0')));
    await tester.pump();

    expect(find.byKey(const ValueKey('answer-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('word-0')), findsNothing);
  });

  testWidgets('tapping an answer word returns it to the cloud', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('word-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('answer-0')));
    await tester.pump();

    expect(find.byKey(const ValueKey('word-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-0')), findsNothing);
  });

  testWidgets('correct order shows the next button', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await solveCurrent(tester);

    expect(find.byKey(const ValueKey('next-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('check-button')), findsNothing);
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('wrong order shakes and resets the answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapWords(tester, _sentence.split(' ').reversed.toList());
    await tester.tap(find.byKey(const ValueKey('check-button')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Сброс: все слова снова в облаке, задание не решено.
    expect(find.byKey(const ValueKey('answer-0')), findsNothing);
    for (var index = 0; index < 6; index++) {
      expect(find.byKey(ValueKey('word-$index')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('check-button')), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('session summary appears after five puzzles', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    for (var round = 0; round < 5; round++) {
      await solveCurrent(tester);
      await tester.tap(find.byKey(const ValueKey('next-button')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Сессия завершена'), findsOneWidget);
    expect(find.text('Верно: 5 из 5'), findsOneWidget);

    await tester.tap(find.text('Ещё раз'));
    await tester.pumpAndSettle();

    expect(find.text('0/5'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-0')), findsOneWidget);
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

    expect(find.text('Sentence Builder'), findsOneWidget);
    expect(find.text('Assemble the sentence'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Check'), findsOneWidget);
  });
}
