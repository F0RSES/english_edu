import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/srs/srs_calculator.dart';
import 'package:english_edu/domain/usecases/get_smart_review_queue.dart';
import 'package:english_edu/domain/usecases/get_today_queue.dart';
import 'package:english_edu/domain/usecases/get_weak_words_queue.dart';
import 'package:english_edu/domain/usecases/record_review.dart';
import 'package:english_edu/domain/usecases/undo_last_review.dart';
import 'package:english_edu/domain/usecases/update_challenge_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/screens/lesson_screen.dart';
import 'package:english_edu/presentation/widgets/word_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/fakes/fake_crash_reporter.dart';
import '../domain/usecases/fakes/fake_daily_challenge_repository.dart';
import '../domain/usecases/fakes/fake_frozen_days_repository.dart';
import '../domain/usecases/fakes/fake_progress_repository.dart';
import '../domain/usecases/fakes/fake_review_log_repository.dart';
import '../domain/usecases/fakes/fake_settings_repository.dart';
import '../domain/usecases/fakes/fake_srs_calculator.dart';
import '../domain/usecases/fakes/fake_stats_repository.dart';
import '../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word(int id) =>
    Word(id: WordId(id), term: 'term$id', translation: 'перевод$id');

WordProgress due(int id) => WordProgress(
  wordId: WordId(id),
  cardState: CardState.initial(now),
  status: WordStatus.learning,
  firstSeenAt: now,
);

/// Проблемное слово: провал, из-за которого оно попадает в weak-очередь.
WordProgress weak(int id) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: 1700,
    intervalDays: 2,
    repetitions: 1,
    lapses: 3,
    dueAt: now.add(const Duration(days: 2)),
  ),
  status: WordStatus.learning,
  firstSeenAt: now,
);

/// Бросает на чтении настроек: проверяет error state экрана.
final class _ThrowingSettings implements SettingsRepository {
  @override
  Future<UserSettings> get() async => throw StateError('boom');

  @override
  Future<void> save(UserSettings settings) async {}
}

/// Бросает при расчёте интервала: проверяет обработку сбоя записи ответа.
final class _ThrowingSrs implements SrsCalculator {
  const _ThrowingSrs();

  @override
  CardState apply(CardState current, ReviewGrade grade, DateTime now) =>
      throw StateError('boom');
}

final class Harness {
  Harness({
    List<Word> words = const [],
    List<WordProgress> progress = const [],
    SettingsRepository? settings,
    SrsCalculator? srs,
  }) : wordRepo = FakeWordRepository(words),
       progressRepo = FakeProgressRepository(progress),
       logRepo = FakeReviewLogRepository(),
       settingsRepo = settings ?? FakeSettingsRepository(),
       srs = srs ?? const FakeSrsCalculator();

  final FakeWordRepository wordRepo;
  final FakeProgressRepository progressRepo;
  final FakeReviewLogRepository logRepo;
  final FakeStatsRepository statsRepo = FakeStatsRepository();
  final SettingsRepository settingsRepo;
  final SrsCalculator srs;
  final FakeCrashReporter crashReporter = FakeCrashReporter();
  var _nextId = 1;

  Widget app({Widget? home}) => ProviderScope(
    overrides: [
      getTodayQueueUseCaseProvider.overrideWithValue(
        GetTodayQueue(
          words: wordRepo,
          progress: progressRepo,
          settings: settingsRepo,
          clock: () => now,
        ),
      ),
      getWeakWordsQueueProvider.overrideWithValue(
        GetWeakWordsQueue(words: wordRepo, progress: progressRepo),
      ),
      getSmartReviewQueueProvider.overrideWithValue(
        GetSmartReviewQueue(
          words: wordRepo,
          progress: progressRepo,
          clock: () => now,
        ),
      ),
      recordReviewProvider.overrideWithValue(
        RecordReview(
          progress: progressRepo,
          reviewLog: logRepo,
          stats: statsRepo,
          words: wordRepo,
          srs: srs,
          nextLogId: () => ReviewLogId(_nextId++),
          clock: () => now,
          challengeProgress: UpdateChallengeProgress(
            repo: FakeDailyChallengeRepository(),
            clock: () => now,
          ),
        ),
      ),
      undoLastReviewProvider.overrideWithValue(
        UndoLastReview(
          progress: progressRepo,
          reviewLog: logRepo,
          stats: statsRepo,
        ),
      ),
      // Главный экран читает серию из тех же репозиториев: без этих
      // override инвалидация нечего пересчитывать.
      statsRepositoryProvider.overrideWithValue(statsRepo),
      frozenDaysRepositoryProvider.overrideWithValue(
        FakeFrozenDaysRepository(),
      ),
      clockProvider.overrideWithValue(() => now),
      crashReporterProvider.overrideWithValue(crashReporter),
    ],
    child: MaterialApp(home: home ?? const LessonScreen()),
  );
}

/// Открывает урок вторым маршрутом: иначе системному back нечего закрывать
/// и `PopScope` не получит `didPop = true`.
Future<void> _pushLesson(WidgetTester tester, Harness harness) async {
  await tester.pumpWidget(
    harness.app(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LessonScreen()),
            ),
            child: const Text('открыть'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the first card of the queue', (tester) async {
    final harness = Harness(words: [word(1)], progress: [due(1)]);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('term1'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('reveals the translation on tap', (tester) async {
    final harness = Harness(words: [word(1)], progress: [due(1)]);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(WordCard));
    await tester.pumpAndSettle();

    expect(find.text('перевод1'), findsOneWidget);
  });

  testWidgets('records a good answer from the button', (tester) async {
    final harness = Harness(words: [word(1)], progress: [due(1)]);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();

    final logs = await harness.logRepo.getAll();
    expect(logs, hasLength(1));
    expect(logs.single.grade, ReviewGrade.good);
  });

  testWidgets('records an again answer from the button', (tester) async {
    final harness = Harness(words: [word(1)], progress: [due(1)]);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Не знаю'));
    await tester.pumpAndSettle();

    final logs = await harness.logRepo.getAll();
    expect(logs.single.grade, ReviewGrade.again);
  });

  testWidgets('shows the summary after the last card', (tester) async {
    final harness = Harness(words: [word(1)], progress: [due(1)]);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();

    expect(find.text('Сессия завершена'), findsOneWidget);
    expect(find.text('Верно: 1 из 1'), findsOneWidget);
  });

  testWidgets('shows an empty state for an empty queue', (tester) async {
    final harness = Harness();

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('На сегодня всё'), findsOneWidget);
  });

  testWidgets('shows a loader before the queue resolves', (tester) async {
    final harness = Harness(words: [word(1)], progress: [due(1)]);

    await tester.pumpWidget(harness.app());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error state when the queue fails', (tester) async {
    final harness = Harness(settings: _ThrowingSettings());

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить очередь'), findsOneWidget);
  });

  testWidgets('disables undo on the summary screen', (tester) async {
    final harness = Harness(words: [word(1)], progress: [due(1)]);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();

    expect(find.text('Сессия завершена'), findsOneWidget);
    final undoButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.undo),
    );
    expect(undoButton.onPressed, isNull);
  });

  testWidgets('summary shows the xp accumulated from outcomes', (tester) async {
    final harness = Harness(
      words: [word(1), word(2), word(3)],
      progress: [due(1), due(2), due(3)],
    );

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Не знаю'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();

    expect(find.text('Верно: 2 из 3'), findsOneWidget);
    expect(find.text('XP: 20'), findsOneWidget);
  });

  testWidgets('invalidates home providers after the session', (tester) async {
    final harness = Harness(words: [word(1)], progress: [due(1)]);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LessonScreen)),
    );

    // До ответа база пуста: серия нулевая, и это уже лежит в кэше.
    expect((await container.read(computeStreakProvider.future)).count, 0);

    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();

    // После сессии кэш сброшен, провайдер пересчитал серию из новых данных.
    expect((await container.read(computeStreakProvider.future)).count, 1);
  });

  testWidgets('back gesture invalidates home providers', (tester) async {
    final harness = Harness(
      words: [word(1), word(2)],
      progress: [due(1), due(2)],
    );

    // Урок открывается вторым маршрутом: системный back должен его закрыть,
    // иначе (на корневом маршруте) callback не получил бы didPop = true.
    await tester.pumpWidget(
      harness.app(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LessonScreen()),
              ),
              child: const Text('открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LessonScreen)),
    );
    // Кэш заполнен значением «активности нет».
    expect((await container.read(computeStreakProvider.future)).count, 0);

    // Данные изменились в обход экрана: без инвалидации кэш остался бы старым.
    await harness.statsRepo.upsert(
      DailyStats(
        date: LocalDate.fromDateTime(now.toLocal()),
        newWordsStudied: 1,
        reviewsCompleted: 0,
        xpGained: 10,
        correctAnswers: 1,
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsNothing);
    expect((await container.read(computeStreakProvider.future)).count, 1);
  });

  testWidgets('back with an active session asks for confirmation', (
    tester,
  ) async {
    final harness = Harness(
      words: [word(1), word(2)],
      progress: [due(1), due(2)],
    );
    await _pushLesson(tester, harness);

    // Один ответ — сессия начата, но не закончена.
    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Завершить сессию?'), findsOneWidget);
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('cancel keeps the session open', (tester) async {
    final harness = Harness(
      words: [word(1), word(2)],
      progress: [due(1), due(2)],
    );
    await _pushLesson(tester, harness);

    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Завершить сессию?'), findsNothing);
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('confirm exits and invalidates the home cache', (tester) async {
    final harness = Harness(
      words: [word(1), word(2)],
      progress: [due(1), due(2)],
    );
    await _pushLesson(tester, harness);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LessonScreen)),
    );
    expect((await container.read(computeStreakProvider.future)).count, 0);

    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsNothing);
    // Ответ записан в stats, и после инвалидации серия пересчитана.
    expect((await container.read(computeStreakProvider.future)).count, 1);
  });

  testWidgets('a failed record review calls the crash reporter', (
    tester,
  ) async {
    final harness = Harness(
      words: [word(1)],
      progress: [due(1)],
      srs: const _ThrowingSrs(),
    );

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Знаю'));
    await tester.pumpAndSettle();

    expect(harness.crashReporter.captured, hasLength(1));
    expect(harness.crashReporter.captured.single.context, 'record_review');
    expect(find.text('Не удалось сохранить ответ'), findsOneWidget);
  });

  testWidgets('weak mode shows only weak words', (tester) async {
    final harness = Harness(
      words: [word(1), word(2)],
      progress: [weak(1), due(2)],
    );

    await tester.pumpWidget(
      harness.app(home: const LessonScreen(mode: LessonMode.weak)),
    );
    await tester.pumpAndSettle();

    // Здоровое слово со сроком в weak-режим не попадает.
    expect(find.text('term1'), findsOneWidget);
    expect(find.text('term2'), findsNothing);
  });

  testWidgets('weak mode uses its own title', (tester) async {
    final harness = Harness(words: [word(1)], progress: [weak(1)]);

    await tester.pumpWidget(
      harness.app(home: const LessonScreen(mode: LessonMode.weak)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сложные слова'), findsOneWidget);
  });

  testWidgets('smart mode uses the smart review queue', (tester) async {
    final harness = Harness(words: [word(1)], progress: [weak(1)]);

    await tester.pumpWidget(
      harness.app(home: const LessonScreen(mode: LessonMode.smart)),
    );
    await tester.pumpAndSettle();

    // Слово с провалами попало в ранжированную очередь, а не в очередь дня.
    expect(find.text('term1'), findsOneWidget);
  });

  testWidgets('smart mode uses its own title', (tester) async {
    final harness = Harness(words: [word(1)], progress: [weak(1)]);

    await tester.pumpWidget(
      harness.app(home: const LessonScreen(mode: LessonMode.smart)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Умное повторение'), findsOneWidget);
  });
}
