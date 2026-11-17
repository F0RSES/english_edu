import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/screens/dictionary_screen.dart';
import 'package:english_edu/presentation/widgets/word_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word(
  int id,
  String term, {
  String? category,
  String? partOfSpeech,
  CefrLevel level = CefrLevel.a1,
}) => Word(
  id: WordId(id),
  term: term,
  translation: 'перевод$term',
  category: category,
  partOfSpeech: partOfSpeech,
  level: level,
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
  UserSettings? settings,
}) => ProviderScope(
  overrides: [
    wordRepositoryProvider.overrideWithValue(FakeWordRepository(words)),
    progressRepositoryProvider.overrideWithValue(
      progressRepo ?? FakeProgressRepository(progress),
    ),
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(settings),
    ),
  ],
  child: const MaterialApp(home: DictionaryScreen()),
);

/// Список — вертикальный ListView; ряд категорий — горизонтальный (Phase 39a).
///
/// Две строки фильтров (уровни и категории) сжимают область списка, поэтому
/// последние слова в ленивом `ListView` могут быть ещё не построены.
final Finder _listScrollable = find
    .descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.vertical,
      ),
      matching: find.byType(Scrollable),
    )
    .first;

/// Горизонтальный ряд чипов категорий: дальние чипы требуют скролла.
final Finder _categoryScrollable = find
    .descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.horizontal,
      ),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> scrollToWord(WidgetTester tester, String term) => tester
    .scrollUntilVisible(find.text(term), 120, scrollable: _listScrollable);

/// Слова разных тематических категорий: фильтр показывает только выбранную.
List<Word> categorizedWords() => [
  word(1, 'apple', category: 'Еда'),
  word(2, 'cat', category: 'Животные'),
  word(3, 'run', partOfSpeech: 'verb'),
];

/// Еда двух уровней плюс животное: фильтры должны складываться по AND.
List<Word> foodLevelWords() => [
  word(1, 'apple', category: 'Еда'),
  word(2, 'banana', category: 'Еда', level: CefrLevel.a2),
  word(3, 'cat', category: 'Животные'),
];

/// Части речи без категорий: POS-фильтр работает по partOfSpeech.
List<Word> posWords() => [
  word(1, 'run', partOfSpeech: 'verb'),
  word(2, 'quick', partOfSpeech: 'adjective'),
  word(3, 'slowly', partOfSpeech: 'adverb'),
  word(4, 'table', partOfSpeech: 'noun'),
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

/// Слова двух уровней и двух категорий: фильтры должны складываться по AND.
List<Word> leveledWords() => [
  word(1, 'apple', category: 'Быт'),
  word(2, 'invoice', category: 'Бизнес', level: CefrLevel.b2),
  word(3, 'server', category: 'IT', level: CefrLevel.b2),
  word(4, 'cat', category: 'Быт'),
];

void main() {
  testWidgets('displays two words with same term if different senses', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        words: [
          const Word(
            id: WordId(1),
            term: 'apple',
            translation: 'яблоко',
            partOfSpeech: 'noun',
          ),
          const Word(
            id: WordId(2),
            term: 'apple',
            translation: 'компания',
            partOfSpeech: 'noun',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Гомонимы видны оба, а часть речи отличает их друг от друга (ADR-031).
    expect(find.text('apple'), findsNWidgets(2));
    expect(find.text('яблоко (noun)'), findsOneWidget);
    expect(find.text('компания (noun)'), findsOneWidget);
  });

  testWidgets('shows every word on the all tab', (tester) async {
    await tester.pumpWidget(
      host(words: sampleWords(), progress: sampleProgress()),
    );
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);

    await scrollToWord(tester, 'fig');

    expect(find.text('fig'), findsOneWidget);
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

    await scrollToWord(tester, 'fig');
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
    expect(find.text('cat'), findsOneWidget);
    expect(find.text('run'), findsOneWidget);
  });

  testWidgets('filters by category and returns to all', (tester) async {
    await tester.pumpWidget(host(words: categorizedWords()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Еда'));
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('cat'), findsNothing);
    expect(find.text('run'), findsNothing);

    // «Все» возвращает весь список.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Все'));
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);
    expect(find.text('run'), findsOneWidget);
  });

  testWidgets('filters by CEFR level', (tester) async {
    await tester.pumpWidget(host(words: leveledWords()));
    await tester.pumpAndSettle();

    // Бейдж в строке тоже содержит 'B2', поэтому берём именно чип-фильтр.
    await tester.tap(find.widgetWithText(ChoiceChip, 'B2'));
    await tester.pumpAndSettle();

    expect(find.text('invoice'), findsOneWidget);
    expect(find.text('server'), findsOneWidget);
    expect(find.text('apple'), findsNothing);
  });

  testWidgets('level filter combined with category filter', (tester) async {
    await tester.pumpWidget(host(words: foodLevelWords()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'A1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Еда'));
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('banana'), findsNothing);
    expect(find.text('cat'), findsNothing);
  });

  testWidgets('renders level row above category row', (tester) async {
    await tester.pumpWidget(host(words: sampleWords()));
    await tester.pumpAndSettle();

    expect(find.text('Категории'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Все уровни'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Все'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Животные'), findsOneWidget);

    final levelRowY = tester
        .getTopLeft(find.widgetWithText(ChoiceChip, 'Все уровни'))
        .dy;
    final categoryLabelY = tester.getTopLeft(find.text('Категории')).dy;
    expect(levelRowY, lessThan(categoryLabelY));
  });

  testWidgets('filters verbs adverbs adjectives by part of speech', (
    tester,
  ) async {
    await tester.pumpWidget(host(words: posWords()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Глаголы'),
      120,
      scrollable: _categoryScrollable,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Глаголы'));
    await tester.pumpAndSettle();
    expect(find.text('run'), findsOneWidget);
    expect(find.text('quick'), findsNothing);
    expect(find.text('table'), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Наречия'),
      120,
      scrollable: _categoryScrollable,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Наречия'));
    await tester.pumpAndSettle();
    expect(find.text('slowly'), findsOneWidget);
    expect(find.text('run'), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Прилагательные'),
      120,
      scrollable: _categoryScrollable,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Прилагательные'));
    await tester.pumpAndSettle();
    expect(find.text('quick'), findsOneWidget);
    expect(find.text('slowly'), findsNothing);
  });

  testWidgets('shows empty category message when nothing matches', (
    tester,
  ) async {
    await tester.pumpWidget(host(words: sampleWords()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Еда'));
    await tester.pumpAndSettle();

    expect(find.text('В этой категории пока пусто'), findsOneWidget);
  });

  testWidgets('switches to EN labels when lang=en', (tester) async {
    await tester.pumpWidget(
      host(settings: const UserSettings(language: AppLanguage.en)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'All levels'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Animals'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Food'), findsOneWidget);
  });

  testWidgets('back button returns to the home screen', (tester) async {
    final router = GoRouter(
      initialLocation: '/dictionary',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('главная')),
        ),
        GoRoute(
          path: '/dictionary',
          builder: (context, state) => const DictionaryScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordRepositoryProvider.overrideWithValue(FakeWordRepository([])),
          progressRepositoryProvider.overrideWithValue(
            FakeProgressRepository([]),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();

    expect(find.text('главная'), findsOneWidget);
  });
}
