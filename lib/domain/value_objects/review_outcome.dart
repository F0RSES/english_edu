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
  });

  /// Состояние карточки после ответа.
  final CardState newCardState;

  /// Сколько XP начислено.
  final int xpGained;

  /// Зачтён ли ответ как верный.
  final bool isCorrect;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewOutcome &&
          newCardState == other.newCardState &&
          xpGained == other.xpGained &&
          isCorrect == other.isCorrect;

  @override
  int get hashCode => Object.hash(newCardState, xpGained, isCorrect);

  @override
  String toString() =>
      'ReviewOutcome(xp: $xpGained, correct: $isCorrect, card: $newCardState)';
}
