import 'package:english_edu/domain/value_objects/challenge_streak.dart';

/// Хранилище серии выполненных заданий дня (Phase 15d, ADR-032).
///
/// Одна запись на устройство: серия — это счётчик, а не журнал, поэтому
/// история дней здесь не хранится (она выводима из `daily_challenges`).
abstract interface class ChallengeStreakRepository {
  /// Возвращает сохранённую серию или null, если задание ещё ни разу
  /// не выполнялось.
  Future<ChallengeStreak?> get();

  /// Сохраняет [streak]; повторная запись заменяет предыдущую.
  ///
  /// `updatedAt` должен быть в UTC: локальное время в БД не хранится.
  Future<void> save(ChallengeStreak streak);
}
