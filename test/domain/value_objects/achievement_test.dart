import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';
import 'package:test/test.dart';

final moment = DateTime.utc(2024, 5, 15, 12);

Achievement achievement({int progress = 3, DateTime? unlockedAt}) =>
    Achievement(
      type: AchievementType.streak7,
      progress: progress,
      unlockedAt: unlockedAt,
      lastUpdatedAt: moment,
    );

void main() {
  test('should_be_locked_without_unlocked_at', () {
    expect(achievement().isUnlocked, isFalse);
    expect(achievement(unlockedAt: moment).isUnlocked, isTrue);
  });

  test('should_clamp_ratio_to_one', () {
    expect(achievement(progress: 0).ratio, 0.0);
    expect(achievement(progress: 70).ratio, 1.0);
  });

  test('should_be_equal_when_all_fields_match', () {
    expect(achievement(), achievement());
    expect(achievement().hashCode, achievement().hashCode);
    expect(achievement(), isNot(achievement(progress: 4)));
  });

  test('should_keep_unlocked_at_when_copy_omits_it', () {
    final unlocked = achievement(unlockedAt: moment);

    expect(unlocked.copyWith(progress: 7).unlockedAt, moment);
  });

  test('should_reject_non_utc_moments', () {
    expect(
      () => Achievement(
        type: AchievementType.streak7,
        progress: 0,
        lastUpdatedAt: DateTime(2024, 5, 15, 12),
      ),
      throwsArgumentError,
    );
  });
}
