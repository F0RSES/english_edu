import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:english_edu/presentation/widgets/ai_word_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_app_meta_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_translation_generator.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

const _translation = WordTranslation(
  text: 'учреждение',
  partOfSpeech: 'noun',
  transcription: '/fəˈsɪləti/',
  example: 'The facility is new.',
);

/// Виджет в изоляции: словарь, прогресс, настройки и переводчик — фейки.
Widget host({
  FakeWordRepository? words,
  FakeTranslationGenerator? generator,
  FakeProgressRepository? progress,
  bool revealWord = true,
}) => ProviderScope(
  overrides: [
    wordRepositoryProvider.overrideWithValue(words ?? FakeWordRepository()),
    progressRepositoryProvider.overrideWithValue(
      progress ?? FakeProgressRepository(),
    ),
    appMetaRepositoryProvider.overrideWithValue(FakeAppMetaRepository()),
    clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 20, 12)),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    translationGeneratorProvider.overrideWithValue(
      generator ?? FakeTranslationGenerator(translation: _translation),
    ),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: AiWordHelper(word: 'facility', revealWord: revealWord),
    ),
  ),
);

void main() {
  testWidgets('renders word when revealWord=true', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('facility'), findsOneWidget);
    expect(find.byKey(const Key('ai-word-avatar')), findsOneWidget);
  });

  testWidgets('renders dont know button when revealWord=false', (tester) async {
    await tester.pumpWidget(host(revealWord: false));
    await tester.pumpAndSettle();

    expect(find.text('Не знаю слово'), findsOneWidget);
    expect(find.text('facility'), findsNothing);
  });

  testWidgets('tap opens sheet with translation', (tester) async {
    final generator = FakeTranslationGenerator(translation: _translation);
    await tester.pumpWidget(host(generator: generator));
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();

    expect(generator.words, ['facility']);
    expect(find.text('учреждение'), findsOneWidget);
    expect(find.text('/fəˈsɪləti/'), findsOneWidget);
    expect(find.text('noun'), findsOneWidget);
    expect(find.text('«The facility is new.»'), findsOneWidget);
  });

  testWidgets('add button opens confirm sheet without inserting', (
    tester,
  ) async {
    final words = FakeWordRepository();
    await tester.pumpWidget(host(words: words));
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // Phase 49: шторка подтверждения открыта, записи ещё нет.
    expect(find.byKey(const Key('confirm-add-word')), findsOneWidget);
    expect(find.text('учреждение'), findsNWidgets(2));
    expect(await words.findByTerm('facility'), isNull);
  });

  testWidgets('confirm plus inserts word with learning status', (tester) async {
    final words = FakeWordRepository();
    final progress = FakeProgressRepository();
    await tester.pumpWidget(host(words: words, progress: progress));
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-add-word')));
    await tester.pumpAndSettle();

    final added = await words.findByTerm('facility');
    expect(added, isNotNull);
    expect(added!.translation, 'учреждение');
    expect(added.partOfSpeech, 'noun');
    // Главное: статус сразу «Изучаю», слово не попадает в «Новое».
    final card = await progress.getByWordId(added.id);
    expect(card, isNotNull);
    expect(card!.status, WordStatus.learning);
    expect(find.text('Слово добавлено в «Изучаю»'), findsOneWidget);
    // Шторка закрыта, лист перевода остался, кнопка стала «удалить».
    expect(find.byKey(const Key('confirm-add-word')), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('cancel closes confirm sheet without inserting', (tester) async {
    final words = FakeWordRepository();
    await tester.pumpWidget(host(words: words));
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-add-cancel')));
    await tester.pumpAndSettle();

    expect(await words.findByTerm('facility'), isNull);
    expect(find.byKey(const Key('confirm-add-word')), findsNothing);
  });

  testWidgets('delete button with confirm removes word', (tester) async {
    final words = FakeWordRepository([
      const Word(id: WordId(1), term: 'facility', translation: 'учреждение'),
    ]);
    await tester.pumpWidget(host(words: words));
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Удалить слово?'), findsOneWidget);
    await tester.tap(find.text('Удалить из словаря'));
    await tester.pumpAndSettle();

    expect(await words.findByTerm('facility'), isNull);
    expect(find.text('Слово удалено'), findsOneWidget);
  });
}
