import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/phrase.dart';
import 'package:english_edu/presentation/screens/phrasebook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

List<Phrase> phrases() => [
  Phrase(
    id: 1,
    phrase: 'How are you?',
    translation: 'Как дела?',
    category: 'Приветствия',
    level: 'a1',
  ),
  Phrase(
    id: 2,
    phrase: 'Where is the gate?',
    translation: 'Где выход на посадку?',
    category: 'Аэропорт',
    level: 'a2',
  ),
];

Widget host() => ProviderScope(
  overrides: [phrasesProvider.overrideWith((ref) async => phrases())],
  child: const MaterialApp(home: PhrasebookScreen()),
);

void main() {
  testWidgets('renders phrases with translations', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('How are you?'), findsOneWidget);
    expect(find.text('Как дела?'), findsOneWidget);
  });

  testWidgets('filters by search query', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'gate');
    await tester.pumpAndSettle();

    expect(find.text('Where is the gate?'), findsOneWidget);
    expect(find.text('How are you?'), findsNothing);
  });

  testWidgets('builds a tab per category', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Все'), findsOneWidget);
    expect(find.text('Приветствия'), findsOneWidget);
    expect(find.text('Аэропорт'), findsOneWidget);
  });
}
