import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/services/word_translator.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:english_edu/presentation/widgets/bulk_dictionary_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_app_meta_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_translation_generator.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

const _words = ['eat', 'eats', 'ate', 'eating', 'eaten'];

final _now = DateTime.utc(2026, 11, 20, 12);

/// Прогресс learning для seed-слова 'eat' (id 1).
WordProgress _learningProgress() => WordProgress(
  wordId: const WordId(1),
  cardState: CardState.initial(_now),
  status: WordStatus.learning,
  firstSeenAt: _now,
);

Widget host({
  FakeWordRepository? words,
  TranslationGenerator? generator,
  FakeProgressRepository? progress,
}) => ProviderScope(
  overrides: [
    wordRepositoryProvider.overrideWithValue(words ?? FakeWordRepository()),
    progressRepositoryProvider.overrideWithValue(
      progress ?? FakeProgressRepository(),
    ),
    appMetaRepositoryProvider.overrideWithValue(FakeAppMetaRepository()),
    clockProvider.overrideWithValue(() => _now),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    translationGeneratorProvider.overrideWithValue(
      generator ?? FakeTranslationGenerator(),
    ),
  ],
  child: const MaterialApp(
    home: Scaffold(body: BulkDictionarySheet(words: _words)),
  ),
);

/// Переводчик, который ждёт Completer: проверка лоадеров.
final class _PendingGenerator implements TranslationGenerator {
  final completer = Completer<WordTranslation>();

  @override
  Future<WordTranslation> translate(String word) => completer.future;
}

void main() {
  testWidgets('renders five words with translations', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Слова в задании'), findsOneWidget);
    for (final word in _words) {
      expect(find.text(word), findsOneWidget);
    }
    expect(find.text('учреждение'), findsNWidgets(5));
    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(5));
  });

  testWidgets('should_add_word_to_learning_when_plus_tapped', (tester) async {
    final words = FakeWordRepository();
    final progress = FakeProgressRepository();
    await tester.pumpWidget(host(words: words, progress: progress));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    final added = await words.findByTerm('eat');
    expect(added, isNotNull);
    expect(added!.translation, 'учреждение');
    expect((await progress.getByWordId(added.id))?.status, WordStatus.learning);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(4));
    expect(find.text('Слово добавлено в «Изучаю»'), findsOneWidget);
  });

  testWidgets('should_show_plus_when_seed_word_has_no_learning_status', (
    tester,
  ) async {
    // Root cause Phase 52b: seed-слово лежит в БД (7415 слов), но пользователь
    // его не добавлял — корзина по факту наличия показывала «уже добавлено».
    final words = FakeWordRepository([
      const Word(id: WordId(1), term: 'eat', translation: 'есть'),
    ]);
    await tester.pumpWidget(host(words: words));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(5));
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('should_show_plus_when_word_is_mastered', (tester) async {
    final words = FakeWordRepository([
      const Word(id: WordId(1), term: 'eat', translation: 'есть'),
    ]);
    final progress = FakeProgressRepository([
      WordProgress(
        wordId: const WordId(1),
        cardState: CardState.initial(_now),
        status: WordStatus.mastered,
        firstSeenAt: _now,
      ),
    ]);
    await tester.pumpWidget(host(words: words, progress: progress));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(5));
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('should_set_learning_without_duplicate_when_plus_on_existing', (
    tester,
  ) async {
    final words = FakeWordRepository([
      const Word(id: WordId(1), term: 'eat', translation: 'есть'),
    ]);
    final progress = FakeProgressRepository();
    await tester.pumpWidget(host(words: words, progress: progress));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    // Seed-перевод не перезаписан, дубликат не создан, статус learning.
    expect(await words.count(), 1);
    expect((await words.findByTerm('eat'))!.translation, 'есть');
    expect(
      (await progress.getByWordId(const WordId(1)))?.status,
      WordStatus.learning,
    );
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('should_remove_progress_but_keep_word_when_trash_tapped', (
    tester,
  ) async {
    final words = FakeWordRepository([
      const Word(id: WordId(1), term: 'eat', translation: 'есть'),
    ]);
    final progress = FakeProgressRepository([_learningProgress()]);
    await tester.pumpWidget(host(words: words, progress: progress));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Слово осталось в словаре («Новое»), прогресс удалён.
    expect(await words.findByTerm('eat'), isNotNull);
    expect(await progress.getByWordId(const WordId(1)), isNull);
    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(5));
    expect(find.text('Слово убрано из «Изучаю»'), findsOneWidget);
  });

  testWidgets('shows loaders while translations are pending', (tester) async {
    final generator = _PendingGenerator();
    await tester.pumpWidget(host(generator: generator));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNWidgets(5));
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);

    generator.completer.complete(const WordTranslation(text: 'перевод'));
    await tester.pumpAndSettle();

    expect(find.text('перевод'), findsNWidgets(5));
  });
}
