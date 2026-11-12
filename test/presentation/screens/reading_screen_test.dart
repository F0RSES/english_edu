import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/reading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_word_repository.dart';

const _story = Story(
  id: 1,
  title: 'My Morning',
  text: 'I wake up at seven. I drink coffee.',
  translation: 'Я просыпаюсь в семь. Я пью кофе.',
  level: CefrLevel.a1,
);

FakeWordRepository wordsWithKnown() => FakeWordRepository([
  const Word(id: WordId(1), term: 'wake', translation: 'просыпаться'),
  const Word(id: WordId(2), term: 'seven', translation: 'семь'),
]);

Widget host(FakeWordRepository words) => ProviderScope(
  overrides: [wordRepositoryProvider.overrideWithValue(words)],
  child: const MaterialApp(home: ReadingScreen(story: _story)),
);

void main() {
  testWidgets('renders title and text', (tester) async {
    await tester.pumpWidget(host(wordsWithKnown()));
    await tester.pumpAndSettle();

    expect(find.text('My Morning'), findsOneWidget);
    expect(find.text(_story.text), findsOneWidget);
  });

  testWidgets('toggle translation works', (tester) async {
    await tester.pumpWidget(host(wordsWithKnown()));
    await tester.pumpAndSettle();

    expect(find.text(_story.translation), findsNothing);

    await tester.tap(find.text('Показать перевод'));
    await tester.pumpAndSettle();
    expect(find.text(_story.translation), findsOneWidget);

    await tester.tap(find.text('Скрыть перевод'));
    await tester.pumpAndSettle();
    expect(find.text(_story.translation), findsNothing);
  });

  testWidgets('unknown words dialog shows count', (tester) async {
    await tester.pumpWidget(host(wordsWithKnown()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Незнакомые слова'));
    await tester.pumpAndSettle();

    // wake и seven известны; drink и coffee — нет.
    expect(find.text('Добавить 2 слова'), findsOneWidget);
  });
}
