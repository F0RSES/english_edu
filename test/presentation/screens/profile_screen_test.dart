import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/daily_goal.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

Widget host() => ProviderScope(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(),
    ),
    computeStreakProvider.overrideWith(
      (ref) async => const StreakInfo(count: 5),
    ),
    dictionaryEntriesProvider.overrideWith((ref) async => const []),
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
    expect(find.text('Все >'), findsOneWidget);
  });

  testWidgets('has no settings controls', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Настройки переехали в SettingsScreen (Phase 20).
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Экспорт'), findsNothing);
  });
}
