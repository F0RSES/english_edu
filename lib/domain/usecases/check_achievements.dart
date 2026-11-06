import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/repositories/achievement_repository.dart';
import 'package:english_edu/domain/repositories/challenge_streak_repository.dart';
import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/usecases/compute_streak.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Пересчитывает достижения и открывает новые (ADR-035).
///
/// Вызывается после ответа (`RecordReview`) и после награды за задание дня:
/// метрики меняются именно там. Возвращает только **только что** открытые
/// достижения — по ним показывается тост; остальные уже известны.
///
/// Метрики берутся из существующих источников, а не хранятся отдельно:
/// серия — `ComputeStreak`, выученные слова — статус прогресса, серия верных
/// ответов — журнал, челленджи — `ChallengeStreak`.
final class CheckAchievements {
  /// Создаёт use case.
  const CheckAchievements({
    required AchievementRepository achievements,
    required StatsRepository stats,
    required ProgressRepository progress,
    required FrozenDaysRepository frozen,
    required ChallengeStreakRepository challengeStreak,
    required ReviewLogRepository reviewLogs,
    required DateTime Function() clock,
  }) : _achievements = achievements,
       _stats = stats,
       _progress = progress,
       _frozen = frozen,
       _challengeStreak = challengeStreak,
       _reviewLogs = reviewLogs,
       _clock = clock;

  final AchievementRepository _achievements;
  final StatsRepository _stats;
  final ProgressRepository _progress;
  final FrozenDaysRepository _frozen;
  final ChallengeStreakRepository _challengeStreak;
  final ReviewLogRepository _reviewLogs;
  final DateTime Function() _clock;

  /// Возвращает достижения, открытые этим вызовом.
  Future<List<Achievement>> call() async {
    final now = _clock().toUtc();
    final stored = await _achievements.getAll();
    final byKey = {for (final item in stored) item.type.key: item};

    final streak = (await ComputeStreak(
      stats: _stats,
      frozen: _frozen,
      clock: _clock,
    )()).count;
    final mastered = (await _progress.getAll())
        .where((item) => item.status == WordStatus.mastered)
        .length;
    final perfect = _longestPerfectRun(await _reviewLogs.getAll());
    final daily = (await _challengeStreak.get())?.current ?? 0;

    final unlocked = <Achievement>[];
    for (final type in AchievementType.values) {
      final current = _metricFor(type, streak, mastered, perfect, daily);
      final existing = byKey[type.key];

      if (existing?.isUnlocked ?? false) {
        continue;
      }

      final reached = current >= type.goal;
      if (!reached && current <= (existing?.progress ?? 0)) {
        continue;
      }

      final updated = Achievement(
        type: type,
        progress: current,
        unlockedAt: reached ? now : null,
        lastUpdatedAt: now,
      );
      await _achievements.save(updated);
      if (reached) {
        unlocked.add(updated);
      }
    }
    return unlocked;
  }

  int _metricFor(
    AchievementType type,
    int streak,
    int mastered,
    int perfect,
    int daily,
  ) => switch (type) {
    AchievementType.streak7 ||
    AchievementType.streak30 ||
    AchievementType.streak100 => streak,
    AchievementType.words100 ||
    AchievementType.words500 ||
    AchievementType.words1000 => mastered,
    AchievementType.perfect10 || AchievementType.perfect50 => perfect,
    AchievementType.daily7 => daily,
  };

  /// Самая длинная серия верных ответов в журнале.
  ///
  /// Журнал append-only и уже отсортирован по вставке, поэтому одного прохода
  /// достаточно; провал (`again`) обрывает серию.
  int _longestPerfectRun(List<ReviewLog> logs) {
    var best = 0;
    var current = 0;
    for (final log in logs) {
      if (log.grade.isFailure) {
        current = 0;
      } else {
        current++;
        if (current > best) {
          best = current;
        }
      }
    }
    return best;
  }
}
