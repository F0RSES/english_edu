import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/error_hunter_screen.dart';
import 'package:english_edu/presentation/widgets/ai_word_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_error_task_generator.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_translation_generator.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

ErrorHunterTask task() => ErrorHunterTask(
  sentence: 'I has a book',
  wrongWord: 'has',
  correctWord: 'have',
  options: const ['have', 'has', 'had'],
);

Widget host(
  FakeErrorTaskGenerator generator, {
  List<Word>? words,
  UserSettings? settings,
}) => ProviderScope(
  overrides: [
    wordRepositoryProvider.overrideWithValue(
      FakeWordRepository(
        words ??
            const [Word(id: WordId(1), term: 'book', translation: 'книга')],
      ),
    ),
    errorTaskGeneratorProvider.overrideWithValue(generator),
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(settings),
    ),
    translationGeneratorProvider.overrideWithValue(FakeTranslationGenerator()),
  ],
  child: const MaterialApp(home: ErrorHunterScreen()),
);

void main() {
  testWidgets('renders loading state', (tester) async {
    final generator = FakeErrorTaskGenerator()..pending = Completer();
    await tester.pumpWidget(host(generator));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(generator.calls, 1);
  });

  testWidgets('renders sentence words', (tester) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    expect(find.text('I'), findsOneWidget);
    expect(find.text('has'), findsOneWidget);
    expect(find.text('book'), findsOneWidget);
    expect(find.text('Найди ошибку и нажми на слово'), findsOneWidget);
  });

  testWidgets('tapping the wrong word shows options', (tester) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('has'));
    await tester.pumpAndSettle();

    expect(find.text('Как правильно?'), findsOneWidget);
    expect(find.text('had'), findsOneWidget);
  });

  testWidgets('tapping a correct word does nothing', (tester) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('book'));
    await tester.pumpAndSettle();

    expect(find.text('Как правильно?'), findsNothing);
  });

  testWidgets('choosing the right option shows success and the next button', (
    tester,
  ) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('has'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('have').last);
    await tester.pumpAndSettle();

    expect(find.text('Следующее задание'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('choosing a wrong option shows an error and keeps the task', (
    tester,
  ) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('has'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('had'));
    await tester.pumpAndSettle();

    expect(find.text('Неверно'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Следующее задание'), findsNothing);
    expect(find.text('book'), findsOneWidget);
  });

  testWidgets('shows the error state with retry when generation fails', (
    tester,
  ) async {
    final generator = FakeErrorTaskGenerator(task())..throwOnGenerate = true;
    await tester.pumpWidget(host(generator));
    await tester.pumpAndSettle();

    expect(
      find.text('Не удалось сгенерировать задание, попробуйте еще раз'),
      findsOneWidget,
    );
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('word helper appears at the corrected word after solve', (
    tester,
  ) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    expect(find.byType(AiWordHelper), findsNothing);

    await tester.tap(find.text('has'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('have').last);
    await tester.pumpAndSettle();

    final helper = tester.widget<AiWordHelper>(find.byType(AiWordHelper));
    expect(helper.word, 'have');
    expect(helper.iconSize, 16);
  });

  testWidgets('bot icon opens translation sheet', (tester) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('has'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('have').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AiWordHelper));
    await tester.pumpAndSettle();

    expect(find.text('учреждение'), findsOneWidget);
  });

  testWidgets('uses only preferredLevel words', (tester) async {
    final generator = FakeErrorTaskGenerator(task());
    await tester.pumpWidget(
      host(
        generator,
        words: const [
          Word(id: WordId(1), term: 'book', translation: 'книга'),
          Word(
            id: WordId(2),
            term: 'facility',
            translation: 'учреждение',
            level: CefrLevel.b1,
          ),
        ],
        settings: const UserSettings(),
      ),
    );
    await tester.pumpAndSettle();

    expect(generator.words, ['book']);
  });

  testWidgets('shows green correctWord after solve', (tester) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('has'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('have').last);
    await tester.pumpAndSettle();

    expect(find.text('has'), findsNothing);
    // 'have' есть и в зелёном чипе, и в helper: проверяем чип предложения.
    final haveInSentence = find.descendant(
      of: find.byType(Wrap),
      matching: find.text('have'),
    );
    expect(haveInSentence, findsOneWidget);
    final container = tester.widget<Container>(
      find.ancestor(of: haveInSentence, matching: find.byType(Container)).first,
    );
    expect(
      container.decoration,
      isA<BoxDecoration>()
          .having((d) => d.color, 'color', Colors.green.withValues(alpha: 0.15))
          .having((d) => d.border, 'border', Border.all(color: Colors.green)),
    );
  });

  testWidgets('app bar title is Russian by default', (tester) async {
    await tester.pumpWidget(host(FakeErrorTaskGenerator(task())));
    await tester.pumpAndSettle();

    expect(find.text('Охота на ошибки'), findsOneWidget);
  });

  testWidgets('app bar title switches to English', (tester) async {
    await tester.pumpWidget(
      host(
        FakeErrorTaskGenerator(task()),
        settings: const UserSettings(language: AppLanguage.en),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Error Hunter'), findsOneWidget);
  });
}
