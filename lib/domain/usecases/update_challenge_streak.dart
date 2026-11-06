import 'package:english_edu/domain/repositories/challenge_streak_repository.dart';
import 'package:english_edu/domain/value_objects/challenge_streak.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// Обновляет серию дней с выполненным заданием (ADR-032).
///
/// Вызывается при выдаче награды (`ClaimDailyChallenge`). Идемпотентен по дню:
/// повторный вызов в тот же день ничего не меняет, поэтому сбой посреди
/// операции можно безопасно повторить.
///
/// Пропуск дня не обнуляет счётчик в ноль, а начинает новую серию с 1: даже
/// один выполненный челлендж — это результат, и «0» обесценил бы возвращение.
final class UpdateChallengeStreak {
  /// Создаёт use case.
  const UpdateChallengeStreak({
    required ChallengeStreakRepository repo,
    required DateTime Function() clock,
  }) : _repo = repo,
       _clock = clock;

  final ChallengeStreakRepository _repo;
  final DateTime Function() _clock;

  /// Отмечает сегодняшний день и возвращает новую серию.
  Future<ChallengeStreak> call() async {
    // День считается по локальному времени пользователя: серия про
    // календарные дни, а не про мгновения.
    final today = LocalDate.fromDateTime(_clock().toLocal());
    final existing =
        await _repo.get() ?? ChallengeStreak.empty(_clock().toUtc());

    // Уже отмечено сегодня — без изменений и без записи в БД.
    if (existing.lastCompletedDate == today) {
      return existing;
    }

    final completedYesterday = existing.lastCompletedDate == today.addDays(-1);
    final current = completedYesterday ? existing.current + 1 : 1;
    final best = current > existing.best ? current : existing.best;

    final updated = existing.copyWith(
      current: current,
      best: best,
      lastCompletedDate: today,
      updatedAt: _clock().toUtc(),
    );
    await _repo.save(updated);
    return updated;
  }
}
