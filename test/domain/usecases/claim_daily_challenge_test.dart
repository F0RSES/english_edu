import 'package:english_edu/domain/usecases/claim_daily_challenge.dart';
import 'package:english_edu/domain/usecases/update_challenge_streak.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

import 'fakes/fake_challenge_streak_repository.dart';
import 'fakes/fake_daily_challenge_repository.dart';
import 'fakes/fake_stats_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now.toLocal());

DailyChallenge completed({DateTime? claimedAt}) => DailyChallenge(
  date: today,
  goalType: DailyChallengeType.noMistakes,
  goalValue: DailyChallengeType.noMistakes.goal,
  progress: DailyChallengeType.noMistakes.goal,
  xpReward: DailyChallengeType.noMistakes.xp,
  claimedAt: claimedAt,
);

ClaimDailyChallenge useCase({
  required FakeDailyChallengeRepository challenges,
  required FakeStatsRepository stats,
  FakeChallengeStreakRepository? streaks,
}) => ClaimDailyChallenge(
  challenges: challenges,
  stats: stats,
  streaks: UpdateChallengeStreak(
    repo: streaks ?? FakeChallengeStreakRepository(),
    clock: () => now,
  ),
  clock: () => now,
);

void main() {
  test('should_claim_completed_challenge_and_add_xp', () async {
    final challenges = FakeDailyChallengeRepository(completed());
    final stats = FakeStatsRepository();
    final claim = useCase(challenges: challenges, stats: stats);

    expect(await claim(), DailyChallengeType.noMistakes.xp);

    final stored = await challenges.getForDate(today);
    expect(stored!.isClaimed, isTrue);
    final todayStats = await stats.getForDate(today);
    expect(todayStats!.xpGained, DailyChallengeType.noMistakes.xp);
  });

  test('should_return_zero_when_goal_is_not_reached', () async {
    final challenges = FakeDailyChallengeRepository(
      DailyChallenge(
        date: today,
        goalType: DailyChallengeType.review20,
        goalValue: DailyChallengeType.review20.goal,
        progress: 3,
        xpReward: DailyChallengeType.review20.xp,
      ),
    );
    final stats = FakeStatsRepository();
    final streaks = FakeChallengeStreakRepository();
    final claim = useCase(
      challenges: challenges,
      stats: stats,
      streaks: streaks,
    );

    expect(await claim(), 0);
    expect(await stats.getForDate(today), isNull);
    expect(
      streaks.saveCount,
      0,
      reason: 'незавершённый челлендж не двигает серию',
    );
  });

  test('should_return_zero_when_reward_is_already_claimed', () async {
    final challenges = FakeDailyChallengeRepository(completed(claimedAt: now));
    final stats = FakeStatsRepository();
    final streaks = FakeChallengeStreakRepository();
    final claim = useCase(
      challenges: challenges,
      stats: stats,
      streaks: streaks,
    );

    expect(await claim(), 0);
    expect(await stats.getForDate(today), isNull);
    expect(
      streaks.saveCount,
      0,
      reason: 'повторная награда не двигает серию',
    );
  });

  test('should_update_streak_on_claim', () async {
    final challenges = FakeDailyChallengeRepository(completed());
    final stats = FakeStatsRepository();
    final streaks = FakeChallengeStreakRepository();

    await useCase(challenges: challenges, stats: stats, streaks: streaks)();

    expect(streaks.stored!.current, 1);
    expect(streaks.stored!.best, 1);
    expect(streaks.stored!.lastCompletedDate, today);
  });
}
