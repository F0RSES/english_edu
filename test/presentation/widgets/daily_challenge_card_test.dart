import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/challenge_streak.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/presentation/widgets/daily_challenge_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
const today = LocalDate(20000);

DailyChallenge challenge({
  DailyChallengeType type = DailyChallengeType.review20,
  int progress = 0,
  DateTime? claimedAt,
}) => DailyChallenge(
  date: today,
  goalType: type,
  goalValue: type.goal,
  progress: progress,
  xpReward: type.xp,
  claimedAt: claimedAt,
);

Widget wrap(DailyChallenge value, {ChallengeStreak? streak}) => ProviderScope(
  overrides: [
    dailyChallengeProvider.overrideWith((ref) async => value),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    // Бейдж серии читает отдельный провайдер: без подмены тест зависел бы от
    // реальной БД.
    challengeStreakProvider.overrideWith(
      (ref) async => streak ?? ChallengeStreak.empty(DateTime.utc(1970)),
    ),
  ],
  child: const MaterialApp(home: Scaffold(body: DailyChallengeCard())),
);

void main() {
  testWidgets('shows progress', (tester) async {
    await tester.pumpWidget(wrap(challenge(progress: 3)));
    await tester.pump();

    expect(find.text('3/20'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.15,
    );
  });

  testWidgets('shows claim button when completed', (tester) async {
    await tester.pumpWidget(wrap(challenge(progress: 20)));
    await tester.pump();

    expect(find.text('Забрать +50 XP'), findsOneWidget);
  });

  testWidgets('shows completed text when claimed', (tester) async {
    await tester.pumpWidget(wrap(challenge(progress: 20, claimedAt: now)));
    await tester.pump();

    expect(find.text('✓ Выполнено'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('shows streak badge', (tester) async {
    await tester.pumpWidget(
      wrap(
        challenge(),
        streak: ChallengeStreak(current: 3, best: 7, updatedAt: now),
      ),
    );
    // Серия читается вторым async-провайдером: одного pump() мало.
    await tester.pumpAndSettle();

    expect(find.text('Серия: 3 дня'), findsOneWidget);
    expect(find.text('Лучший: 7'), findsOneWidget);
  });
}
