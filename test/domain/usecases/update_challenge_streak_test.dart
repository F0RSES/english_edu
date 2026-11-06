import 'package:english_edu/domain/usecases/update_challenge_streak.dart';
import 'package:english_edu/domain/value_objects/challenge_streak.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

import 'fakes/fake_challenge_streak_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now.toLocal());
final LocalDate yesterday = today.addDays(-1);

ChallengeStreak seeded({
  required int current,
  required int best,
  required LocalDate last,
}) => ChallengeStreak(
  current: current,
  best: best,
  lastCompletedDate: last,
  updatedAt: now,
);

UpdateChallengeStreak useCase(FakeChallengeStreakRepository repo) =>
    UpdateChallengeStreak(repo: repo, clock: () => now);

void main() {
  test('should_start_streak_at_one_on_first_claim', () async {
    final repo = FakeChallengeStreakRepository();

    final result = await useCase(repo)();

    expect(result.current, 1);
    expect(result.best, 1);
    expect(result.lastCompletedDate, today);
    expect(repo.saveCount, 1);
  });

  test('should_increment_when_yesterday_was_completed', () async {
    final repo = FakeChallengeStreakRepository(
      seeded(current: 3, best: 5, last: yesterday),
    );

    final result = await useCase(repo)();

    expect(result.current, 4);
    expect(result.best, 5);
  });

  test('should_restart_at_one_when_a_day_was_missed', () async {
    final repo = FakeChallengeStreakRepository(
      seeded(current: 4, best: 4, last: today.addDays(-3)),
    );

    final result = await useCase(repo)();

    // Не 0: один выполненный челлендж — уже результат.
    expect(result.current, 1);
    expect(result.best, 4);
  });

  test('should_not_change_when_today_is_already_counted', () async {
    final existing = seeded(current: 2, best: 2, last: today);
    final repo = FakeChallengeStreakRepository(existing);

    final result = await useCase(repo)();

    expect(result, existing);
    expect(repo.saveCount, 0);
  });

  test('should_raise_best_when_current_exceeds_it', () async {
    final repo = FakeChallengeStreakRepository(
      seeded(current: 5, best: 5, last: yesterday),
    );

    final result = await useCase(repo)();

    expect(result.current, 6);
    expect(result.best, 6);
  });

  test('should_preserve_best_when_current_is_lower', () async {
    final repo = FakeChallengeStreakRepository(
      seeded(current: 2, best: 10, last: yesterday),
    );

    final result = await useCase(repo)();

    expect(result.current, 3);
    expect(result.best, 10);
  });
}
