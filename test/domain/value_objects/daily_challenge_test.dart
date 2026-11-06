import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

const date = LocalDate(20000);
final moment = DateTime.utc(2024, 5, 15, 12);

DailyChallenge challenge({
  int progress = 0,
  DateTime? completedAt,
  DateTime? claimedAt,
}) => DailyChallenge(
  date: date,
  goalType: DailyChallengeType.review20,
  goalValue: DailyChallengeType.review20.goal,
  progress: progress,
  xpReward: DailyChallengeType.review20.xp,
  completedAt: completedAt,
  claimedAt: claimedAt,
);

void main() {
  test('should_be_completed_when_progress_reaches_goal', () {
    expect(challenge(progress: 19).isCompleted, isFalse);
    expect(challenge(progress: 20).isCompleted, isTrue);
    expect(challenge(progress: 25).isCompleted, isTrue);
  });

  test('should_be_claimed_only_when_claimed_at_is_set', () {
    expect(challenge().isClaimed, isFalse);
    expect(challenge(claimedAt: moment).isClaimed, isTrue);
  });

  test('should_clamp_ratio_between_zero_and_one', () {
    expect(challenge().ratio, 0.0);
    expect(challenge(progress: 10).ratio, 0.5);
    expect(challenge(progress: 40).ratio, 1.0);
  });

  test('should_keep_nullable_moments_when_copy_is_called_without_them', () {
    final original = challenge(progress: 5, completedAt: moment);

    expect(original.copyWith(progress: 6).completedAt, moment);
  });

  test('should_clear_nullable_moments_when_null_is_passed', () {
    final original = challenge(completedAt: moment, claimedAt: moment);

    expect(original.copyWith(completedAt: null).completedAt, isNull);
    expect(original.copyWith(claimedAt: null).claimedAt, isNull);
  });

  test('should_be_equal_when_all_fields_match', () {
    expect(challenge(progress: 3), challenge(progress: 3));
    expect(challenge(progress: 3).hashCode, challenge(progress: 3).hashCode);
    expect(challenge(progress: 3), isNot(challenge(progress: 4)));
  });

  test('should_reject_non_utc_moment', () {
    expect(
      () => challenge(completedAt: DateTime(2024, 5, 15, 12)),
      throwsArgumentError,
    );
  });
}
