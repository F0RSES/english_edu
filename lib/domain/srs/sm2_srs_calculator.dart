import 'package:english_edu/domain/srs/srs_calculator.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';

/// Минимальный ease-фактор SM-2 в permille: 1.3.
const _minEasePermille = 1300;

/// Стандартный SM-2 с четырёхуровневой градацией.
///
/// `easePermille = 1000 * EF`. Easy/Good/Hard/Again маппятся на качество
/// 5/4/3/0. Чистая функция: нет I/O и нет обращения к системным часам.
///
/// Throws [ArgumentError] if `now` is not UTC. Проверка runtime, не assert —
/// release-safe.
final class Sm2SrsCalculator implements SrsCalculator {
  /// Создаёт калькулятор; состояние между вызовами не хранится.
  const Sm2SrsCalculator();

  @override
  CardState apply(CardState current, ReviewGrade grade, DateTime now) {
    // Runtime-проверка, не assert: в release assert вырезается, а тихая
    // ошибка часового пояса дороже исключения.
    if (!now.isUtc) {
      throw ArgumentError.value(now, 'now', 'must be UTC');
    }

    // EF' = EF + (0.1 - (5-q)(0.08 + (5-q)*0.02)), пересчитанный в permille:
    // q=5 → +100, q=4 → 0, q=3 → -140, q=0 → -800.
    final ease = _clampEase(current.easePermille + _easeDeltaPermille(grade));

    final int repetitions;
    final int lapses;
    final int interval;
    if (grade == ReviewGrade.again) {
      repetitions = 0;
      lapses = current.lapses + 1;
      interval = 1;
    } else {
      repetitions = current.repetitions + 1;
      lapses = current.lapses;
      interval = switch (repetitions) {
        1 => 1,
        2 => 6,
        _ => _scaledInterval(current.intervalDays, ease),
      };
    }

    return CardState(
      easePermille: ease,
      intervalDays: interval,
      repetitions: repetitions,
      lapses: lapses,
      // Не выравниваем на полночь: это улучшение Phase 3.
      dueAt: now.add(Duration(days: interval)),
    );
  }

  int _easeDeltaPermille(ReviewGrade grade) => switch (grade) {
    ReviewGrade.again => -800,
    ReviewGrade.hard => -140,
    ReviewGrade.good => 0,
    ReviewGrade.easy => 100,
  };

  int _clampEase(int easePermille) =>
      easePermille < _minEasePermille ? _minEasePermille : easePermille;

  /// interval * (EF/1.0), округлённый к ближайшему, но не меньше суток.
  int _scaledInterval(int currentIntervalDays, int easePermille) {
    final rounded = (currentIntervalDays * easePermille / 1000).round();
    return rounded < 1 ? 1 : rounded;
  }
}
