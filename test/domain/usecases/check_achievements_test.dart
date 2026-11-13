import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/repositories/achievement_repository.dart';
import 'package:english_edu/domain/usecases/check_achievements.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

import 'fakes/fake_challenge_streak_repository.dart';
import 'fakes/fake_chat_repository.dart';
import 'fakes/fake_frozen_days_repository.dart';
import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_review_log_repository.dart';
import 'fakes/fake_stats_repository.dart';
import 'fakes/fake_typing_record_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now.toLocal());

/// Достижения в памяти: use case проверяется без БД.
final class FakeAchievementRepository implements AchievementRepository {
  final Map<String, Achievement> _items = {};

  @override
  Future<List<Achievement>> getAll() async => _items.values.toList();

  @override
  Future<Achievement?> getByType(AchievementType type) async =>
      _items[type.key];

  @override
  Future<void> save(Achievement achievement) async {
    _items[achievement.type.key] = achievement;
  }
}

/// N подряд идущих активных дней: этого достаточно для серии.
List<DailyStats> activeDays(int count) => [
  for (var offset = 0; offset < count; offset++)
    DailyStats(
      date: today.addDays(-offset),
      newWordsStudied: 1,
      reviewsCompleted: 0,
      xpGained: 10,
      correctAnswers: 1,
    ),
];

CheckAchievements useCase(
  FakeAchievementRepository achievements, {
  int streakDays = 0,
}) => CheckAchievements(
  achievements: achievements,
  stats: FakeStatsRepository(activeDays(streakDays)),
  progress: FakeProgressRepository(),
  frozen: FakeFrozenDaysRepository(),
  challengeStreak: FakeChallengeStreakRepository(),
  reviewLogs: FakeReviewLogRepository(),
  chat: FakeChatRepository(),
  typing: FakeTypingRecordRepository(),
  clock: () => now,
);

void main() {
  test('should_unlock_streak_achievement_at_goal', () async {
    final repo = FakeAchievementRepository();

    final unlocked = await useCase(repo, streakDays: 7)();

    expect(
      unlocked.map((item) => item.type),
      contains(AchievementType.streak7),
    );
    expect((await repo.getByType(AchievementType.streak7))!.isUnlocked, isTrue);
  });

  test('should_not_unlock_twice', () async {
    final repo = FakeAchievementRepository();
    await useCase(repo, streakDays: 7)();

    final second = await useCase(repo, streakDays: 7)();

    expect(second, isEmpty);
  });

  test('should_record_progress_without_unlocking', () async {
    final repo = FakeAchievementRepository();

    await useCase(repo, streakDays: 3)();

    final stored = await repo.getByType(AchievementType.streak7);
    expect(stored!.progress, 3);
    expect(stored.isUnlocked, isFalse);
  });
}
