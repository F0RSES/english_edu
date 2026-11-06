import 'package:english_edu/domain/usecases/update_challenge_progress.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:test/test.dart';

import 'fakes/fake_daily_challenge_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now.toLocal());

DailyChallenge seeded(DailyChallengeType type, {int progress = 0}) =>
    DailyChallenge(
      date: today,
      goalType: type,
      goalValue: type.goal,
      progress: progress,
      xpReward: type.xp,
    );

UpdateChallengeProgress useCase(FakeDailyChallengeRepository repo) =>
    UpdateChallengeProgress(repo: repo, clock: () => now);

Future<DailyChallenge> reload(FakeDailyChallengeRepository repo) async =>
    (await repo.getForDate(today))!;

void main() {
  test('should_increment_on_each_review_for_review20', () async {
    final repo = FakeDailyChallengeRepository(
      seeded(DailyChallengeType.review20),
    );
    final progress = useCase(repo);

    await progress(grade: ReviewGrade.good, isFirstResponse: false);
    await progress(grade: ReviewGrade.again, isFirstResponse: false);

    expect((await reload(repo)).progress, 2);
  });

  test('should_reset_to_zero_when_again_is_graded_for_streak10', () async {
    final repo = FakeDailyChallengeRepository(
      seeded(DailyChallengeType.streak10, progress: 4),
    );

    await useCase(repo)(grade: ReviewGrade.again, isFirstResponse: false);

    expect((await reload(repo)).progress, 0);
  });

  test('should_count_only_first_response_for_new5', () async {
    final repo = FakeDailyChallengeRepository(seeded(DailyChallengeType.new5));
    final progress = useCase(repo);

    await progress(grade: ReviewGrade.good, isFirstResponse: false);
    expect((await reload(repo)).progress, 0);

    await progress(grade: ReviewGrade.good, isFirstResponse: true);
    expect((await reload(repo)).progress, 1);
  });

  test('should_keep_progress_when_hard_is_graded_for_noMistakes', () async {
    final repo = FakeDailyChallengeRepository(
      seeded(DailyChallengeType.noMistakes, progress: 3),
    );
    final progress = useCase(repo);

    await progress(grade: ReviewGrade.hard, isFirstResponse: false);
    expect((await reload(repo)).progress, 3);
    expect(repo.saveCount, 0, reason: 'нейтральный ответ не пишется в БД');

    await progress(grade: ReviewGrade.good, isFirstResponse: false);
    expect((await reload(repo)).progress, 4);

    await progress(grade: ReviewGrade.again, isFirstResponse: false);
    expect((await reload(repo)).progress, 0);
  });

  test('should_mark_completed_when_goal_is_reached', () async {
    final repo = FakeDailyChallengeRepository(
      seeded(DailyChallengeType.review20, progress: 19),
    );

    await useCase(repo)(grade: ReviewGrade.good, isFirstResponse: false);

    final stored = await reload(repo);
    expect(stored.progress, 20);
    expect(stored.isCompleted, isTrue);
    expect(stored.completedAt, now);
  });

  test('should_skip_when_challenge_is_absent', () async {
    final repo = FakeDailyChallengeRepository();

    await useCase(repo)(grade: ReviewGrade.good, isFirstResponse: false);

    expect(repo.saveCount, 0);
  });
}
