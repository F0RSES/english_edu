import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
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
  exampleRu: 'Учреждение новое.',
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
    expect(find.byKey(const Key('app-bottom-sheet-handle')), findsOneWidget);
    // Phase 52a: транскрипция без обрамляющих слэшей.
    expect(find.text('fəˈsɪləti'), findsOneWidget);
    expect(find.text('noun'), findsOneWidget);
    expect(find.text('EN: The facility is new.'), findsOneWidget);
    expect(find.text('RU: Учреждение новое.'), findsOneWidget);
  });

  testWidgets('action button adds word with learning and switches to remove', (
    tester,
  ) async {
    final words = FakeWordRepository();
    final progress = FakeProgressRepository();
    await tester.pumpWidget(host(words: words, progress: progress));
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();

    // Phase 51: одна шторка, одна кнопка действия; второй шторки нет.
    expect(find.byKey(const Key('word-action-button')), findsOneWidget);
    expect(find.text('Добавить в изучение'), findsOneWidget);

    await tester.tap(find.byKey(const Key('word-action-button')));
    await tester.pumpAndSettle();

    final added = await words.findByTerm('facility');
    expect(added, isNotNull);
    expect(added!.translation, 'учреждение');
    final card = await progress.getByWordId(added.id);
    expect(card!.status, WordStatus.learning);
    expect(find.text('Слово добавлено в «Изучаю»'), findsOneWidget);
    // Кнопка сменилась на корзину, шторка осталась одна.
    expect(find.text('Удалить из изучения'), findsOneWidget);
    expect(find.byKey(const Key('word-action-button')), findsOneWidget);
  });

  testWidgets('second tap removes progress but keeps the word', (tester) async {
    final words = FakeWordRepository();
    final progress = FakeProgressRepository();
    await tester.pumpWidget(host(words: words, progress: progress));
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('word-action-button')));
    await tester.pumpAndSettle();
    // SnackBar перекрывает низ шторки — ждём автозакрытия перед вторым тапом.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('word-action-button')));
    await tester.pumpAndSettle();

    // Прогресс удалён, слово осталось в словаре («Новое»).
    final word = await words.findByTerm('facility');
    expect(word, isNotNull);
    expect(await progress.getByWordId(word!.id), isNull);
    expect(find.text('Слово убрано из «Изучаю»'), findsOneWidget);
    expect(find.text('Добавить в изучение'), findsOneWidget);
  });

  testWidgets('existing mastered word shows add button and sets learning', (
    tester,
  ) async {
    final words = FakeWordRepository([
      const Word(id: WordId(1), term: 'facility', translation: 'учреждение'),
    ]);
    final progress = FakeProgressRepository([
      WordProgress(
        wordId: const WordId(1),
        cardState: CardState.initial(DateTime.utc(2026, 11, 20, 12)),
        status: WordStatus.mastered,
        firstSeenAt: DateTime.utc(2026, 11, 20, 12),
      ),
    ]);
    await tester.pumpWidget(host(words: words, progress: progress));
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();

    // mastered ≠ learning → кнопка «+», одна (без корзины).
    expect(find.text('Добавить в изучение'), findsOneWidget);
    expect(find.text('Удалить из изучения'), findsNothing);

    await tester.tap(find.byKey(const Key('word-action-button')));
    await tester.pumpAndSettle();

    // Дубликата нет: тот же id; статус переведён в learning.
    final found = await words.findByTerm('facility');
    expect(found!.id, const WordId(1));
    final card = await progress.getByWordId(const WordId(1));
    expect(card!.status, WordStatus.learning);
    expect(find.text('Удалить из изучения'), findsOneWidget);
  });
}
