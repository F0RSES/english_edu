import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../domain/usecases/fakes/fake_frozen_days_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_stats_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now);

Word word(int id) =>
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id');

WordProgress fresh(int id) => WordProgress(
  wordId: WordId(id),
  cardState: CardState.initial(now),
  status: WordStatus.newWord,
  firstSeenAt: now,
);

/// Слово с провалом: попадает в очередь «сложных» (ADR-026).
WordProgress weak(int id) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: 1700,
    intervalDays: 2,
    repetitions: 1,
    lapses: 2,
    dueAt: now.add(const Duration(days: 2)),
  ),
  status: WordStatus.learning,
  firstSeenAt: now.subtract(const Duration(days: 7)),
);

/// Пять активных дней подряд, сегодня — пять ответов.
List<DailyStats> fiveDayStreak() => [
  DailyStats(
    date: today,
    newWordsStudied: 3,
    reviewsCompleted: 2,
    xpGained: 50,
    correctAnswers: 5,
  ),
  for (var offset = 1; offset < 5; offset++)
    DailyStats(
      date: today.addDays(-offset),
      newWordsStudied: 1,
      reviewsCompleted: 0,
      xpGained: 10,
      correctAnswers: 1,
    ),
];

/// Ломается на любом чтении прогресса: проверяет error state очереди.
final class _ThrowingProgress implements ProgressRepository {
  @override
  Future<WordProgress?> getByWordId(WordId wordId) async =>
      throw StateError('boom');

  @override
  Future<List<WordProgress>> getByStatus(WordStatus status) async =>
      throw StateError('boom');

  @override
  Future<List<WordProgress>> getAll() async => throw StateError('boom');

  @override
  Future<List<WordProgress>> getDueBefore(DateTime utcInstant) async =>
      throw StateError('boom');

  @override
  Future<void> upsert(WordProgress progress) async {}

  @override
  Future<void> replaceAll(Iterable<WordProgress> items) async {}
}

/// Ломается на чтении статистики: карточка цели должна пережить это.
final class _ThrowingStats implements StatsRepository {
  @override
  Future<DailyStats?> getForDate(LocalDate date) async =>
      throw StateError('boom');

  @override
  Future<List<DailyStats>> getRange(LocalDate from, LocalDate to) async =>
      throw StateError('boom');

  @override
  Future<LocalDate?> getLastActiveDate() async => throw StateError('boom');

  @override
  Future<List<DailyStats>> getAll() async => throw StateError('boom');

  @override
  Future<void> upsert(DailyStats stats) async {}

  @override
  Future<void> replaceAll(Iterable<DailyStats> items) async {}
}

Widget app({
  List<Word> words = const [],
  ProgressRepository? progress,
  StatsRepository? stats,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/lesson',
        builder: (context, state) => const Scaffold(body: Text('экран урока')),
      ),
      GoRoute(
        path: '/dictionary',
        builder: (context, state) =>
            const Scaffold(body: Text('экран словаря')),
      ),
      GoRoute(
        path: '/weak-words',
        builder: (context, state) =>
            const Scaffold(body: Text('экран сложных слов')),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const Scaffold(body: Text('экран профиля')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => now),
      wordRepositoryProvider.overrideWithValue(FakeWordRepository(words)),
      progressRepositoryProvider.overrideWithValue(
        progress ?? FakeProgressRepository(),
      ),
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      statsRepositoryProvider.overrideWithValue(stats ?? FakeStatsRepository()),
      frozenDaysRepositoryProvider.overrideWithValue(
        FakeFrozenDaysRepository(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('renders streak, daily goal and start button', (tester) async {
    await tester.pumpWidget(
      app(
        words: [word(1), word(2)],
        progress: FakeProgressRepository([fresh(1), fresh(2)]),
        stats: FakeStatsRepository(fiveDayStreak()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('дней подряд'), findsOneWidget);
    expect(find.text('5 / 60 слов сегодня'), findsOneWidget);
    expect(find.text('Начать урок (2 слова)'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('enables the start button when the queue is not empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        words: [word(1), word(2)],
        progress: FakeProgressRepository([fresh(1), fresh(2)]),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('disables the start button when the queue is empty', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Все слова изучены'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('navigates to the lesson screen after a tap', (tester) async {
    await tester.pumpWidget(
      app(words: [word(1)], progress: FakeProgressRepository([fresh(1)])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Начать урок (1 слово)'));
    await tester.pumpAndSettle();

    expect(find.text('экран урока'), findsOneWidget);
  });

  testWidgets('shows a spinner while the queue loads', (tester) async {
    await tester.pumpWidget(
      app(words: [word(1)], progress: FakeProgressRepository([fresh(1)])),
    );

    // Без settle: на первом кадре результат очереди ещё неизвестен.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('shows a retry action when the queue fails', (tester) async {
    await tester.pumpWidget(app(progress: _ThrowingProgress()));
    await tester.pumpAndSettle();

    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('recomputes the goal after invalidation', (tester) async {
    final stats = FakeStatsRepository();
    await tester.pumpWidget(app(stats: stats));
    await tester.pumpAndSettle();

    expect(find.text('0 / 60 слов сегодня'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await stats.upsert(
      DailyStats(
        date: today,
        newWordsStudied: 4,
        reviewsCompleted: 0,
        xpGained: 40,
        correctAnswers: 4,
      ),
    );
    container.invalidate(dailyGoalProvider);
    await tester.pumpAndSettle();

    expect(find.text('4 / 60 слов сегодня'), findsOneWidget);
  });

  testWidgets('keeps the goal card when stats fail', (tester) async {
    await tester.pumpWidget(app(stats: _ThrowingStats()));
    await tester.pumpAndSettle();

    // Падение статистики не должно уносить экран: карточка показывает план
    // по умолчанию, а старт урока остаётся доступным.
    expect(find.text('0 / 60 слов сегодня'), findsOneWidget);
    expect(find.text('Все слова изучены'), findsOneWidget);
  });

  testWidgets('shows weak words button when count > 0', (tester) async {
    await tester.pumpWidget(
      app(words: [word(1)], progress: FakeProgressRepository([weak(1)])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Повторить сложные (1)'), findsOneWidget);
  });

  testWidgets('hides weak words button when count == 0', (tester) async {
    await tester.pumpWidget(app(words: [word(1)]));
    await tester.pumpAndSettle();

    expect(find.textContaining('Повторить сложные'), findsNothing);
  });

  testWidgets('tapping weak words navigates to /weak-words', (tester) async {
    await tester.pumpWidget(
      app(words: [word(1)], progress: FakeProgressRepository([weak(1)])),
    );
    await tester.pumpAndSettle();

    // Кнопка ниже сгиба: на главной уже три кнопки игр.
    await tester.scrollUntilVisible(find.text('Повторить сложные (1)'), 200);
    await tester.tap(find.text('Повторить сложные (1)'));
    await tester.pumpAndSettle();

    expect(find.text('экран сложных слов'), findsOneWidget);
  });
}
