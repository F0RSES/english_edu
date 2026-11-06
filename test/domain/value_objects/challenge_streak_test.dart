import 'package:english_edu/domain/value_objects/challenge_streak.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

final moment = DateTime.utc(2024, 5, 15, 12);
const today = LocalDate(20000);

ChallengeStreak streak({int current = 0, int best = 0, LocalDate? last}) =>
    ChallengeStreak(
      current: current,
      best: best,
      lastCompletedDate: last,
      updatedAt: moment,
    );

void main() {
  test('should_be_equal_when_all_fields_match', () {
    expect(streak(current: 3, best: 5), streak(current: 3, best: 5));
    expect(
      streak(current: 3, best: 5).hashCode,
      streak(current: 3, best: 5).hashCode,
    );
    expect(streak(current: 3, best: 5), isNot(streak(current: 4, best: 5)));
  });

  test('should_replace_counters_on_copy', () {
    final copy = streak(current: 1, best: 1).copyWith(current: 7, best: 7);

    expect(copy.current, 7);
    expect(copy.best, 7);
  });

  test('should_keep_last_date_when_copy_omits_it', () {
    final original = streak(current: 2, last: today);

    expect(original.copyWith(current: 3).lastCompletedDate, today);
  });

  test('should_clear_last_date_when_null_is_passed', () {
    final original = streak(last: today);
    final cleared = original.copyWith(lastCompletedDate: null);

    expect(cleared.lastCompletedDate, isNull);
  });

  test('should_start_from_zero_with_empty_factory', () {
    final empty = ChallengeStreak.empty(moment);

    expect(empty.current, 0);
    expect(empty.best, 0);
    expect(empty.lastCompletedDate, isNull);
    expect(empty.updatedAt, moment);
  });

  test('should_reject_non_utc_updated_at', () {
    expect(
      () => ChallengeStreak(
        current: 0,
        best: 0,
        updatedAt: DateTime(2024, 5, 15, 12),
      ),
      throwsArgumentError,
    );
  });
}
