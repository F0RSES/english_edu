import 'dart:math';

import 'package:english_edu/domain/usecases/get_or_create_daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

import 'fakes/fake_daily_challenge_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now.toLocal());

void main() {
  test('should_return_existing_challenge_when_day_already_started', () async {
    final existing = DailyChallenge(
      date: today,
      goalType: DailyChallengeType.new5,
      goalValue: DailyChallengeType.new5.goal,
      progress: 2,
      xpReward: DailyChallengeType.new5.xp,
    );
    final repo = FakeDailyChallengeRepository(existing);
    final useCase = GetOrCreateDailyChallenge(
      repo: repo,
      clock: () => now,
      random: Random(1),
    );

    final result = await useCase();

    expect(result, existing);
    expect(repo.saveCount, 0);
  });

  test('should_create_and_save_challenge_when_day_is_empty', () async {
    final repo = FakeDailyChallengeRepository();
    final useCase = GetOrCreateDailyChallenge(
      repo: repo,
      clock: () => now,
      random: Random(1),
    );

    final result = await useCase();

    expect(result.date, today);
    expect(result.progress, 0);
    expect(result.goalType, DailyChallengeType.values[Random(1).nextInt(4)]);
    expect(result.goalValue, result.goalType.goal);
    expect(result.xpReward, result.goalType.xp);
    expect(repo.saveCount, 1);
  });
}
