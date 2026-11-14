import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/phrase.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/presentation/screens/phrasebook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

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

Widget host({UserSettings? settings}) => ProviderScope(
  overrides: [
    phrasesProvider.overrideWith((ref) async => phrases()),
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(settings),
    ),
  ],
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

    expect(find.widgetWithText(Tab, 'Все'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Приветствия'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Аэропорт'), findsOneWidget);
  });

  testWidgets('app bar title is Russian by default', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Разговорник'), findsOneWidget);
  });

  testWidgets('app bar title switches to English', (tester) async {
    await tester.pumpWidget(
      host(settings: const UserSettings(language: AppLanguage.en)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phrasebook'), findsOneWidget);
  });
}
