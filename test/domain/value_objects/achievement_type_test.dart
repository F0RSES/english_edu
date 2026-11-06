import 'package:english_edu/domain/value_objects/achievement_type.dart';
import 'package:test/test.dart';

void main() {
  test('should_expose_nine_achievements', () {
    expect(AchievementType.values, hasLength(9));
  });

  test('should_keep_unique_keys_and_positive_goals', () {
    final keys = {for (final type in AchievementType.values) type.key};

    expect(keys, hasLength(9));
    for (final type in AchievementType.values) {
      expect(type.goal, greaterThan(0));
      expect(type.title, isNotEmpty);
      expect(type.icon, isNotEmpty);
    }
  });

  test('should_restore_type_from_key', () {
    for (final type in AchievementType.values) {
      expect(AchievementType.fromKey(type.key), type);
    }
  });

  test('should_return_null_for_unknown_key', () {
    expect(AchievementType.fromKey('no_such'), isNull);
  });
}
