import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/presentation/screens/reading_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

List<Story> stories() => const [
  Story(
    id: 1,
    title: 'My Morning',
    text: 'I wake up at seven. I eat breakfast.',
    translation: 'Я просыпаюсь в семь. Я завтракаю.',
    level: CefrLevel.a1,
  ),
  Story(
    id: 2,
    title: 'At the Airport',
    text: 'Sarah arrived at the airport. She checked in her luggage.',
    translation: 'Сара приехала в аэропорт. Она сдала багаж.',
    level: CefrLevel.a2,
  ),
];

Widget host({List<Story> Function(CefrLevel level)? byLevel}) => ProviderScope(
  overrides: [
    storiesByLevelProvider.overrideWith(
      (ref, level) async =>
          byLevel?.call(level) ??
          [
            for (final story in stories())
              if (story.level == level) story,
          ],
    ),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
  ],
  child: const MaterialApp(home: ReadingListScreen()),
);

void main() {
  testWidgets('renders stories', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('My Morning'), findsOneWidget);
  });

  testWidgets('filters by CEFR', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'A2'));
    await tester.pumpAndSettle();

    expect(find.text('At the Airport'), findsOneWidget);
    expect(find.text('My Morning'), findsNothing);
  });

  testWidgets('empty state', (tester) async {
    await tester.pumpWidget(host(byLevel: (_) => const []));
    await tester.pumpAndSettle();

    expect(find.text('Рассказы не загружены'), findsOneWidget);
  });
}
