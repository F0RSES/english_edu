import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:meta/meta.dart';

/// Marker telling "absent" apart from an explicit null in a copy.
const _unset = _Unset();

final class _Unset {
  const _Unset();
}

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

/// Серия дней подряд с выполненным ежедневным заданием (ADR-032).
///
/// Второй мотивационный контур рядом с основной серией дней (ADR-015): там
/// считается активность, здесь — выполнение задания дня.
///
/// Не `const`: `updatedAt` проверяется на UTC в runtime, потому что `assert`
/// вырезается в release (как у `WordProgress` и `DailyChallenge`).
@immutable
final class ChallengeStreak {
  /// Создаёт снимок серии; [updatedAt] должен быть в UTC.
  ChallengeStreak({
    required this.current,
    required this.best,
    required DateTime updatedAt,
    this.lastCompletedDate,
  }) : updatedAt = _requireUtc(updatedAt, 'updatedAt'),
       assert(current >= 0, 'current must be >= 0'),
       assert(best >= 0, 'best must be >= 0');

  /// Серия без единого выполненного задания.
  factory ChallengeStreak.empty(DateTime updatedAt) =>
      ChallengeStreak(current: 0, best: 0, updatedAt: updatedAt);

  /// Длина текущей серии в локальных днях.
  final int current;

  /// Лучшая серия за всё время; только растёт.
  final int best;

  /// День последнего выполненного задания; null — ещё ни одного.
  final LocalDate? lastCompletedDate;

  /// Момент последнего изменения, UTC.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  ///
  /// [lastCompletedDate] очищается явной передачей null; пропуск параметра
  /// сохраняет текущее значение.
  ChallengeStreak copyWith({
    int? current,
    int? best,
    DateTime? updatedAt,
    Object? lastCompletedDate = _unset,
  }) => ChallengeStreak(
    current: current ?? this.current,
    best: best ?? this.best,
    updatedAt: updatedAt ?? this.updatedAt,
    lastCompletedDate: identical(lastCompletedDate, _unset)
        ? this.lastCompletedDate
        : lastCompletedDate as LocalDate?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeStreak &&
          current == other.current &&
          best == other.best &&
          lastCompletedDate == other.lastCompletedDate &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(current, best, lastCompletedDate, updatedAt);

  @override
  String toString() =>
      'ChallengeStreak(current: $current, best: $best, '
      'last: $lastCompletedDate)';
}
