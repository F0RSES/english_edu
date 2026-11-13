/// Правила выдачи заморозок серии (ADR-015).
///
/// Freeze начисляется по milestones: 1 за 7 дней, ещё 1 за 30, максимум 2.
/// Значение — не баланс, а потолок: сколько заморозок пользователь заработал
/// к текущей длине серии. Сколько из них уже израсходовано, знает хранилище.
abstract final class StreakRule {
  /// Сколько заморозок заработано при серии длиной [streakCount].
  static int frozenEarnedFor(int streakCount) {
    var earned = 0;
    if (streakCount >= _firstMilestone) {
      earned++;
    }
    if (streakCount >= _secondMilestone) {
      earned++;
    }
    return earned;
  }

  /// Потолок одновременно доступных заморозок.
  static const int maxAvailable = 2;

  /// Первая веха: 7 дней подряд.
  static const int _firstMilestone = 7;

  /// Вторая веха: 30 дней подряд.
  static const int _secondMilestone = 30;
}
