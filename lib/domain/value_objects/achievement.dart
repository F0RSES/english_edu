import 'package:english_edu/domain/value_objects/achievement_type.dart';
import 'package:meta/meta.dart';

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

DateTime? _requireUtcOrNull(DateTime? value, String name) =>
    value == null ? null : _requireUtc(value, name);

/// Состояние одного достижения: прогресс и момент открытия (ADR-035).
///
/// Не `const`: моменты проверяются на UTC в runtime, потому что `assert`
/// вырезается в release (как у `WordProgress` и `ChallengeStreak`).
@immutable
final class Achievement {
  /// Создаёт состояние; оба момента должны быть в UTC.
  Achievement({
    required this.type,
    required this.progress,
    required DateTime lastUpdatedAt,
    DateTime? unlockedAt,
  }) : lastUpdatedAt = _requireUtc(lastUpdatedAt, 'lastUpdatedAt'),
       unlockedAt = _requireUtcOrNull(unlockedAt, 'unlockedAt'),
       assert(progress >= 0, 'progress must be >= 0');

  /// Что за достижение.
  final AchievementType type;

  /// Текущее значение метрики (не больше и не меньше факта).
  final int progress;

  /// Момент открытия, UTC; null — ещё закрыто.
  final DateTime? unlockedAt;

  /// Момент последнего пересчёта, UTC.
  final DateTime lastUpdatedAt;

  /// Открыто ли достижение.
  bool get isUnlocked => unlockedAt != null;

  /// Доля выполнения `0.0..1.0` — для полоски прогресса.
  double get ratio =>
      type.goal == 0 ? 0 : (progress / type.goal).clamp(0.0, 1.0);

  /// Returns a copy with the given fields replaced.
  Achievement copyWith({
    AchievementType? type,
    int? progress,
    DateTime? lastUpdatedAt,
    Object? unlockedAt = _unset,
  }) => Achievement(
    type: type ?? this.type,
    progress: progress ?? this.progress,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    unlockedAt: identical(unlockedAt, _unset)
        ? this.unlockedAt
        : unlockedAt as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          type == other.type &&
          progress == other.progress &&
          unlockedAt == other.unlockedAt &&
          lastUpdatedAt == other.lastUpdatedAt;

  @override
  int get hashCode => Object.hash(type, progress, unlockedAt, lastUpdatedAt);

  @override
  String toString() =>
      'Achievement(${type.key}, $progress/${type.goal}, '
      'unlocked: $unlockedAt)';
}

/// Marker telling "absent" apart from an explicit null in a copy.
const _unset = _Unset();

final class _Unset {
  const _Unset();
}
