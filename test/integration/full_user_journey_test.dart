import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:english_edu/core/crash_reporter.dart';
import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/notifications/notification_service.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/main.dart';
import 'package:english_edu/presentation/widgets/add_word_dialog.dart';
import 'package:english_edu/presentation/widgets/swipe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Проверяет ВСЕ пути сквозь приложение на реальной БД: онбординг, урок,
/// словарь, экспорт и ежедневное задание. Каждый шаг идёт через настоящие
/// виджеты и настоящие репозитории (in-memory SQLite), а не через фейки.
///
/// Если шаг падает — тест показывает, на каком экране сценарий сломался.
/// Reset и Import живут в `profile_screen_test` и `import_dialog_test`: там
/// они уже покрыты, дублировать их здесь смысла нет.

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now.toLocal());

domain.Word word(int id) => domain.Word(
  id: WordId(id),
  term: 'term$id',
  translation: 'перевод$id',
);

/// Приложение целиком: тот же `EnglishEduApp`, что и в `main`.
///
/// Подменяются только точки, которых в тестовой среде нет: база, часы,
/// нативные сервисы сбоев и напоминаний.
/// Счётчик id журнала: в `main` его даёт `NextReviewLogIdGenerator` (ADR-009),
/// а провайдер по умолчанию бросает `UnimplementedError`.
var _logId = 1;

Widget app(AppDatabase db, {bool onboardingSeen = false}) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(() => now),
    nextReviewLogIdProvider.overrideWithValue(() => ReviewLogId(_logId++)),
    crashReporterProvider.overrideWithValue(const NoOpCrashReporter()),
    notificationServiceProvider.overrideWithValue(
      const NoOpNotificationService(),
    ),
    onboardingSeenProvider.overrideWith(
      () => OnboardingSeen(seeded: onboardingSeen),
    ),
  ],
  child: const EnglishEduApp(),
);

Future<AppDatabase> seededDb(List<domain.Word> words) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await DriftWordRepository(db).insertMany(words);
  return db;
}

/// Прокачивает кадры, пока не завершится асинхронная работа с БД, но не
/// доходит до 4-секундного таймера SnackBar.
///
/// `pumpAndSettle` для этого не годится: он прокручивает и таймер, из-за чего
/// SnackBar исчезает раньше проверки.
Future<void> settleShort(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Высокий экран вместо дефолтных 800×600: на телефоне блоки не наезжают друг
/// на друга, и тапы не попадают в `NavigationBar` / `SnackBar`.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('full journey: onboarding, lesson and daily goal', (
    tester,
  ) async {
    useTallScreen(tester);
    final db = await seededDb([word(1), word(2)]);
    addTearDown(db.close);

    await tester.pumpWidget(app(db));
    await tester.pumpAndSettle();

    // 1. Первый запуск ведёт на онбординг.
    expect(find.text('Учи слова легко'), findsOneWidget);

    // 2. Три слайда «Далее» и выбор уровня на последней странице.
    for (var page = 0; page < 3; page++) {
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Какой у тебя уровень?'), findsOneWidget);
    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();

    // 3. Главная: очередь собрана из двух новых слов.
    expect(find.text('Начать урок'), findsOneWidget);
    expect(find.text('Error Hunter'), findsOneWidget);

    // 4. Урок: обе карточки оценены кнопкой «Знаю».
    await tester.tap(find.text('Начать урок'));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);

    // Свайп вправо = «знаю». Кнопки «Не знаю»/«Знаю» лежат под SnackBar
    // «+10 XP», поэтому идём тем путём, которым пользуется пользователь.
    await tester.fling(find.byType(SwipeCard), const Offset(500, 0), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(SwipeCard), const Offset(500, 0), 1200);
    await tester.pumpAndSettle();

    // 5. Итоги сессии: два ответа записаны в журнал.
    final logs = await db.select(db.reviewLogs).get();
    expect(logs, hasLength(2), reason: 'оба ответа дошли до БД');
    expect(find.text('Верно: 2 из 2'), findsOneWidget);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();

    // 6. Дневная цель пересчитана: два ответа из 60 (10 новых + 50 повторов).
    expect(find.text('2 / 60 слов сегодня'), findsOneWidget);
  });

  testWidgets('journey: adding a word through the dictionary', (
    tester,
  ) async {
    final db = await seededDb([word(1)]);
    addTearDown(db.close);

    await tester.pumpWidget(app(db, onboardingSeen: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Словарь'));
    await tester.pumpAndSettle();
    expect(find.text('term1'), findsOneWidget);

    await tester.tap(find.byTooltip('Добавить слово'));
    await tester.pumpAndSettle();

    // Поля ищем только внутри диалога: на экране есть ещё поле поиска.
    final fields = find.descendant(
      of: find.byType(AddWordDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'test');
    await tester.enterText(fields.at(1), 'тест');
    await tester.tap(find.text('Добавить'));
    await settleShort(tester);

    expect(find.text('Добавлено'), findsOneWidget);
    expect(find.text('test'), findsOneWidget);
  });

  testWidgets('journey: challenge claim, streak badge and export dialog', (
    tester,
  ) async {
    useTallScreen(tester);
    final db = await seededDb([word(1)]);
    addTearDown(db.close);
    // Выполненное задание дня уже в базе: награда ждёт нажатия.
    await db
        .into(db.dailyChallenges)
        .insert(
          DailyChallengesCompanion.insert(
            dateEpochDays: Value(today.daysSinceEpoch),
            goalType: 'review20',
            goalValue: 20,
            progress: const Value(20),
            xpReward: 50,
          ),
        );

    await tester.pumpWidget(app(db, onboardingSeen: true));
    await tester.pumpAndSettle();

    // 7. Задание дня: награда доступна и начисляется.
    final claim = find.widgetWithText(FilledButton, 'Забрать +50 XP');
    await tester.ensureVisible(claim);
    await tester.pumpAndSettle();
    await tester.tap(claim);
    await settleShort(tester);

    // Награда записана в БД.
    final row = await db.select(db.dailyChallenges).getSingle();
    expect(row.claimedAtUtc, isNotNull);
    // Карточка перестроилась: кнопка сменилась на отметку.
    expect(find.text('✓ Выполнено'), findsOneWidget);
    // Серия челленджей выросла до 1 (первый claim).
    expect(find.text('Серия: 1 день'), findsOneWidget);
    expect(find.text('✓ Выполнено'), findsOneWidget);
    // Первый claim поднимает серию челленджей до 1.
    expect(find.text('Серия: 1 день'), findsOneWidget);

    // SnackBar живёт 4 с и перекрывает нижнюю навигацию: даём ему уйти.
    await tester.pumpAndSettle();

    // 8. Настройки: диалог экспорта собирает JSON из текущего состояния
    // (Phase 20: экспорт переехал из профиля в настройки).
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Экспорт'), 200);
    await tester.tap(find.text('Экспорт'));
    await tester.pumpAndSettle();

    expect(find.text('Скопировать'), findsOneWidget);
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text('Скопировать'), findsNothing);
  });
}
