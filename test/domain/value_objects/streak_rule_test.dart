import 'package:english_edu/domain/value_objects/streak_rule.dart';
import 'package:test/test.dart';

void main() {
  group('StreakRule.frozenEarnedFor', () {
    test('grants nothing before seven days', () {
      expect(StreakRule.frozenEarnedFor(0), 0);
      expect(StreakRule.frozenEarnedFor(6), 0);
    });

    test('grants one freeze at seven days', () {
      expect(StreakRule.frozenEarnedFor(7), 1);
    });

    test('keeps one freeze up to twenty-nine days', () {
      expect(StreakRule.frozenEarnedFor(29), 1);
    });

    test('grants two freezes at thirty days', () {
      expect(StreakRule.frozenEarnedFor(30), 2);
    });

    test('never grants more than the cap', () {
      expect(StreakRule.frozenEarnedFor(100), StreakRule.maxAvailable);
    });
  });

  test('maxAvailable is two', () {
    expect(StreakRule.maxAvailable, 2);
  });
}
