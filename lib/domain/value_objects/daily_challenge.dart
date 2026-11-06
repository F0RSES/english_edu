import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:meta/meta.dart';

/// Marker telling "absent" apart from an explicit null in a copy.
const _unset = _Unset();

final class _Unset {
  const _Unset();
}

DateTime? _requireUtcOrNull(DateTime? value, String name) {
  if (value == null) {
    return null;
  }
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

/// Ежедневное задание: цель на локальный день и прогресс по ней (ADR-030).
///
/// Не `const`: `completedAt`/`claimedAt` проверяются на UTC в runtime, потому
/// что `assert` вырезается в release, а локальное время в БД сломало бы
/// сравнения и экспорт.
@immutable
final class DailyChallenge {
  /// Создаёт задание; оба момента должны быть в UTC.
  ///
  /// [progress] может уменьшаться: серийные задания сбрасываются провалом.
  DailyChallenge({
    required this.date,
    required this.goalType,
    required this.goalValue,
    required this.progress,
    required this.xpReward,
    DateTime? completedAt,
    DateTime? claimedAt,
  }) : completedAt = _requireUtcOrNull(completedAt, 'completedAt'),
       claimedAt = _requireUtcOrNull(claimedAt, 'claimedAt'),
       assert(goalValue >= 0, 'goalValue must be >= 0'),
       assert(progress >= 0, 'progress must be >= 0'),
       assert(xpReward >= 0, 'xpReward must be >= 0');

  /// Локальный день, к которому относится задание.
  final LocalDate date;

  /// Тип задания.
  final DailyChallengeType goalType;

  /// Сколько единиц нужно набрать; приходит из [goalType].
  final int goalValue;

  /// Набранный прогресс.
  final int progress;

  /// Момент выполнения, UTC; null — цель ещё не достигнута.
  final DateTime? completedAt;

  /// Момент получения награды, UTC; null — награда не забрана.
  final DateTime? claimedAt;

  /// Сколько XP начисляется за награду; приходит из [goalType].
  final int xpReward;

  /// Достигнута ли цель.
  bool get isCompleted => progress >= goalValue;

  /// Забрана ли награда.
  bool get isClaimed => claimedAt != null;

  /// Доля выполнения в диапазоне `0.0..1.0` — для индикатора прогресса.
  double get ratio =>
      goalValue == 0 ? 0 : (progress / goalValue).clamp(0.0, 1.0);

  /// Returns a copy with the given fields replaced.
  ///
  /// [completedAt] и [claimedAt] очищаются явной передачей null; пропуск
  /// параметра сохраняет текущее значение.
  DailyChallenge copyWith({
    LocalDate? date,
    DailyChallengeType? goalType,
    int? goalValue,
    int? progress,
    Object? completedAt = _unset,
    Object? claimedAt = _unset,
    int? xpReward,
  }) => DailyChallenge(
    date: date ?? this.date,
    goalType: goalType ?? this.goalType,
    goalValue: goalValue ?? this.goalValue,
    progress: progress ?? this.progress,
    completedAt: identical(completedAt, _unset)
        ? this.completedAt
        : completedAt as DateTime?,
    claimedAt: identical(claimedAt, _unset)
        ? this.claimedAt
        : claimedAt as DateTime?,
    xpReward: xpReward ?? this.xpReward,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyChallenge &&
          date == other.date &&
          goalType == other.goalType &&
          goalValue == other.goalValue &&
          progress == other.progress &&
          completedAt == other.completedAt &&
          claimedAt == other.claimedAt &&
          xpReward == other.xpReward;

  @override
  int get hashCode => Object.hash(
    date,
    goalType,
    goalValue,
    progress,
    completedAt,
    claimedAt,
    xpReward,
  );

  @override
  String toString() =>
      'DailyChallenge($date, ${goalType.name}, '
      '$progress/$goalValue, completed: $completedAt, claimed: $claimedAt)';
}
