import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:meta/meta.dart';

/// Результат записи одного ответа.
///
/// Нужен UI: XP и признак верного ответа считаются в домене, а не на экране.
@immutable
final class ReviewOutcome {
  /// Создаёт результат.
  const ReviewOutcome({
    required this.newCardState,
    required this.xpGained,
    required this.isCorrect,
    this.newlyUnlockedAchievements = const [],
  });

  /// Состояние карточки после ответа.
  final CardState newCardState;

  /// Сколько XP начислено.
  final int xpGained;

  /// Зачтён ли ответ как верный.
  final bool isCorrect;

  /// Достижения, открытые этим ответом (ADR-035). Пусто, если нечего показать.
  final List<Achievement> newlyUnlockedAchievements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewOutcome &&
          newCardState == other.newCardState &&
          xpGained == other.xpGained &&
          isCorrect == other.isCorrect &&
          _sameAchievements(
            newlyUnlockedAchievements,
            other.newlyUnlockedAchievements,
          );

  @override
  int get hashCode => Object.hash(
    newCardState,
    xpGained,
    isCorrect,
    Object.hashAll(newlyUnlockedAchievements),
  );

  @override
  String toString() =>
      'ReviewOutcome(xp: $xpGained, correct: $isCorrect, card: $newCardState)';
}

bool _sameAchievements(List<Achievement> left, List<Achievement> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
