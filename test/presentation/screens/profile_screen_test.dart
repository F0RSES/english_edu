import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/analytics.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/daily_goal.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

Widget host({
  UserSettings? settings,
  FakeSettingsRepository? repository,
  Analytics? analytics,
}) => ProviderScope(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(
      repository ?? FakeSettingsRepository(settings),
    ),
    computeStreakProvider.overrideWith(
      (ref) async => const StreakInfo(count: 5),
    ),
    analyticsProvider.overrideWith(
      (ref) async =>
          analytics ??
          Analytics(
            totalWords: 2071,
            masteredCount: 7,
            learningCount: 3,
            newCount: 2061,
            hardestWords: const [],
            last7Days: const [],
          ),
    ),
    dailyGoalProvider.overrideWith(
      (ref) async => const DailyGoal(stats: null, target: 60),
    ),
    achievementsProvider.overrideWith((ref) async => const []),
    clockProvider.overrideWithValue(() => DateTime.utc(2024, 5, 15, 12)),
  ],
  child: const MaterialApp(home: ProfileScreen()),
);

void main() {
  testWidgets('has a back button in the app bar', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('shows identity and statistics', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Learner'), findsOneWidget);
    expect(find.textContaining('Уровень:'), findsOneWidget);
    expect(find.text('Серия'), findsOneWidget);
    expect(find.text('Слов'), findsOneWidget);
  });

  testWidgets('shows the achievements block', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.textContaining('Достижения ('), findsOneWidget);
    expect(find.byTooltip('Все достижения'), findsOneWidget);
    // chevron_right есть и у карточки помощника — проверяем наличие.
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
  });

  testWidgets('words metric shows mastered count, not dictionary size', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // masteredCount = 7, а не 2071 слово словаря (Phase 28a).
    expect(find.text('7'), findsOneWidget);
    expect(find.text('2071'), findsNothing);
  });

  testWidgets('has no analytics block', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Трудные слова'), findsNothing);
    expect(find.text('Пока нет провалов'), findsNothing);
    expect(find.textContaining('Прогноз mastery'), findsNothing);
  });

  testWidgets('has no settings controls', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Настройки переехали в SettingsScreen (Phase 20).
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Экспорт'), findsNothing);
  });

  testWidgets('shows nickname from settings', (tester) async {
    await tester.pumpWidget(
      host(settings: const UserSettings(nickname: 'Norman')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Norman'), findsOneWidget);
    expect(find.text('Learner'), findsNothing);
  });

  testWidgets('tap edit opens dialog', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Введите никнейм'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);
  });

  testWidgets('saving nickname updates settings', (tester) async {
    final repository = FakeSettingsRepository();
    await tester.pumpWidget(host(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Введите никнейм'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Norman');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect((await repository.get()).nickname, 'Norman');
    expect(find.text('Norman'), findsOneWidget);
    expect(find.text('Никнейм сохранён'), findsOneWidget);
  });

  testWidgets('shows the weekly chart with seven bars', (tester) async {
    final today = LocalDate.fromDateTime(DateTime.utc(2024, 5, 15, 12));
    await tester.pumpWidget(
      host(
        analytics: Analytics(
          totalWords: 10,
          masteredCount: 1,
          learningCount: 2,
          newCount: 7,
          hardestWords: const [],
          last7Days: [
            for (var offset = 6; offset >= 0; offset--)
              DailyStats(
                date: today.addDays(-offset),
                newWordsStudied: 1,
                reviewsCompleted: 0,
                xpGained: 0,
                correctAnswers: 1,
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('weekChart')), findsOneWidget);
    expect(find.text('За 7 дней'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> && key.value.startsWith('bar-');
      }),
      findsNWidgets(7),
    );
  });

  testWidgets('weekly chart header switches to English', (tester) async {
    await tester.pumpWidget(
      host(settings: const UserSettings(language: AppLanguage.en)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last 7 days'), findsOneWidget);
  });
}
