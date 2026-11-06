import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/error_hunter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_error_task_generator.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

ErrorHunterTask task() => ErrorHunterTask(
  sentence: 'I has a book',
  wrongWord: 'has',
  correctWord: 'have',
  options: const ['have', 'has', 'had'],
);

Widget host(FakeErrorTaskGenerator generator) => ProviderScope(
  overrides: [
    wordRepositoryProvider.overrideWithValue(
      FakeWordRepository([
        const Word(id: WordId(1), term: 'book', translation: 'книга'),
      ]),
    ),
    errorTaskGeneratorProvider.overrideWithValue(generator),
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

    expect(find.text('Верно!'), findsOneWidget);
    expect(find.text('Следующее задание'), findsOneWidget);
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

    expect(find.text('Ошибка'), findsOneWidget);
    expect(find.text('Следующее задание'), findsNothing);
    expect(find.text('book'), findsOneWidget);
  });

  testWidgets('shows the error state with retry when generation fails', (
    tester,
  ) async {
    final generator = FakeErrorTaskGenerator(task())..throwOnGenerate = true;
    await tester.pumpWidget(host(generator));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить задание'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}
