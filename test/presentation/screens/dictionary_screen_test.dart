import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/screens/dictionary_screen.dart';
import 'package:english_edu/presentation/widgets/word_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word(int id, String term, {String? category}) => Word(
  id: WordId(id),
  term: term,
  translation: 'перевод$term',
  category: category,
);

WordProgress progress(int id, WordStatus status) => WordProgress(
  wordId: WordId(id),
  cardState: CardState.initial(now),
  status: status,
  firstSeenAt: now,
);

final class _ThrowingProgress implements ProgressRepository {
  @override
  Future<WordProgress?> getByWordId(WordId wordId) async => null;

  @override
  Future<List<WordProgress>> getByStatus(WordStatus status) async => [];

  @override
  Future<List<WordProgress>> getAll() async => throw StateError('boom');

  @override
  Future<List<WordProgress>> getDueBefore(DateTime utcInstant) async => [];

  @override
  Future<void> upsert(WordProgress progress) async {}

  @override
  Future<void> replaceAll(Iterable<WordProgress> items) async {}
}

Widget host({
  List<Word> words = const [],
  List<WordProgress> progress = const [],
  ProgressRepository? progressRepo,
}) => ProviderScope(
  overrides: [
    wordRepositoryProvider.overrideWithValue(FakeWordRepository(words)),
    progressRepositoryProvider.overrideWithValue(
      progressRepo ?? FakeProgressRepository(progress),
    ),
  ],
  child: const MaterialApp(home: DictionaryScreen()),
);

/// Слова разных категорий: фильтр должен показывать только выбранную.
List<Word> categorizedWords() => [
  word(1, 'apple', category: 'Быт'),
  word(2, 'invoice', category: 'Бизнес'),
  word(3, 'server', category: 'IT'),
];

List<Word> sampleWords() => [
  word(1, 'apple'),
  word(2, 'banana'),
  word(3, 'cherry'),
  word(4, 'date'),
  word(5, 'fig'),
];

List<WordProgress> sampleProgress() => [
  progress(1, WordStatus.learning),
  progress(2, WordStatus.learning),
  progress(3, WordStatus.mastered),
];

void main() {
  testWidgets('shows every word on the all tab', (tester) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progress: sampleProgress()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WordListItem), findsNWidgets(5));
  });

  testWidgets('filters the learning tab', (tester) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progress: sampleProgress()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Изучаю'));
    await tester.pumpAndSettle();

    expect(find.byType(WordListItem), findsNWidgets(2));
  });

  testWidgets('filters the mastered tab', (tester) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progress: sampleProgress()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Выучено'));
    await tester.pumpAndSettle();

    expect(find.byType(WordListItem), findsNWidgets(1));
  });

  testWidgets('shows words without progress only on the all tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progress: sampleProgress()),
    );
    await tester.pumpAndSettle();

    expect(find.text('fig'), findsOneWidget);

    await tester.tap(find.text('Изучаю'));
    await tester.pumpAndSettle();

    expect(find.text('fig'), findsNothing);
  });

  testWidgets('searches through the repository', (tester) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progress: sampleProgress()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ban');
    await tester.pumpAndSettle();

    expect(find.byType(WordListItem), findsNWidgets(1));
    expect(find.text('banana'), findsOneWidget);
  });

  testWidgets('shows an empty state for an empty dictionary', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Словарь пуст — добавьте первое слово'), findsOneWidget);
  });

  testWidgets('shows an empty state when nothing matches', (tester) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progress: sampleProgress()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('shows a loader while loading', (tester) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progress: sampleProgress()),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error state with retry', (tester) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progressRepo: _ThrowingProgress()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить словарь'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('shows words of every category by default', (tester) async {
    await tester.pumpWidget(host(words: categorizedWords()));
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('invoice'), findsOneWidget);
    expect(find.text('server'), findsOneWidget);
  });

  testWidgets('filters by category and returns to all', (tester) async {
    await tester.pumpWidget(host(words: categorizedWords()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Бизнес'));
    await tester.pumpAndSettle();

    expect(find.text('invoice'), findsOneWidget);
    expect(find.text('apple'), findsNothing);
    expect(find.text('server'), findsNothing);

    // «Все» возвращает весь список.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Все категории'));
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('server'), findsOneWidget);
  });
}
