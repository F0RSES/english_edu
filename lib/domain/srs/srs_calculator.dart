import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';

/// Чистая функция SM-2. Реализация — Phase 1.1c.
///
/// Не зависит от системных часов: `dueAt` нового состояния вычисляется из
/// переданного `now`, поэтому тесты детерминированы.
abstract interface class SrsCalculator {
  /// Applies [grade] to [current] and returns the next card state.
  ///
  /// [now] must be in UTC; implementations assert `now.isUtc`.
  CardState apply(CardState current, ReviewGrade grade, DateTime now);
}
