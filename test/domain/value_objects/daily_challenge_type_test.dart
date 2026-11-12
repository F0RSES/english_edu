import 'dart:math';

import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:test/test.dart';

void main() {
  test('should_expose_goal_and_reward_for_every_type', () {
    expect(DailyChallengeType.values, hasLength(4));

    expect(DailyChallengeType.review20.goal, 20);
    expect(DailyChallengeType.review20.xp, 50);
    expect(DailyChallengeType.streak10.goal, 10);
    expect(DailyChallengeType.streak10.xp, 30);
    expect(DailyChallengeType.new5.goal, 5);
    expect(DailyChallengeType.new5.xp, 40);
    expect(DailyChallengeType.noMistakes.goal, 10);
    expect(DailyChallengeType.noMistakes.xp, 60);
  });

  test('should_pick_deterministic_type_when_random_is_seeded', () {
    final expected = DailyChallengeType.values[Random(7).nextInt(4)];

    expect(DailyChallengeType.random(Random(7)), expected);
  });

  test('should_restore_type_from_name', () {
    for (final type in DailyChallengeType.values) {
      expect(DailyChallengeType.fromName(type.name), type);
    }
  });

  test('should_throw_when_name_is_unknown', () {
    expect(() => DailyChallengeType.fromName('weekly5'), throwsArgumentError);
  });
}
