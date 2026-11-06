import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/repositories/daily_challenge_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/usecases/update_challenge_streak.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// Выдаёт награду за выполненное задание дня (ADR-030) и отмечает день в
/// серии выполненных заданий (ADR-032).
///
/// Отдельный use case, а не логика в виджете: XP пишется в `DailyStats`, а
/// presentation не имеет права ходить в репозитории напрямую.
final class ClaimDailyChallenge {
  /// Создаёт use case.
  const ClaimDailyChallenge({
    required DailyChallengeRepository challenges,
    required StatsRepository stats,
    required UpdateChallengeStreak streaks,
    required DateTime Function() clock,
  }) : _challenges = challenges,
       _stats = stats,
       _streaks = streaks,
       _clock = clock;

  final DailyChallengeRepository _challenges;
  final StatsRepository _stats;
  final UpdateChallengeStreak _streaks;
  final DateTime Function() _clock;

  /// Начисляет награду и возвращает её размер; 0 — забирать нечего.
  ///
  /// 0 возвращается, когда задания нет, цель не достигнута или награда уже
  /// забрана: повторное нажатие не должно начислять XP дважды.
  Future<int> call() async {
    final today = LocalDate.fromDateTime(_clock().toLocal());
    final challenge = await _challenges.getForDate(today);
    if (challenge == null || !challenge.isCompleted || challenge.isClaimed) {
      return 0;
    }

    // Серия обновляется до записи награды: шаг идемпотентен по дню, поэтому
    // повтор после сбоя не задвоит счётчик, а пользователь не получит XP без
    // отмеченного дня.
    await _streaks();

    await _challenges.save(challenge.copyWith(claimedAt: _clock().toUtc()));

    final current = await _stats.getForDate(today) ?? DailyStats.empty(today);
    await _stats.upsert(
      current.copyWith(xpGained: current.xpGained + challenge.xpReward),
    );
    return challenge.xpReward;
  }
}
